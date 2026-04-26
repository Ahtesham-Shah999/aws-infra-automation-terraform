#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# blue_green_deploy.sh – Task 7 Blue-Green Deployment Script
#
# Usage:
#   ./blue_green_deploy.sh <image_uri> <git_sha> <branch>
#
# Environment variables required:
#   AWS_REGION         – AWS region
#   MAIN_LISTENER_ARN  – ARN of the ALB main listener
#   TEST_LISTENER_ARN  – ARN of the ALB test listener (port 8080)
#   TG_BLUE_ARN        – ARN of the Blue target group
#   TG_GREEN_ARN       – ARN of the Green target group
#   ASG_BLUE           – Name of the Blue ASG
#   ASG_GREEN          – Name of the Green ASG
#   DEPLOY_LOG_BUCKET  – S3 bucket for deployment log
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

IMAGE_URI="${1}"
GIT_SHA="${2}"
BRANCH="${3}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "==> Starting Blue-Green deployment"
echo "    Image:     ${IMAGE_URI}"
echo "    Git SHA:   ${GIT_SHA}"
echo "    Branch:    ${BRANCH}"

# ── Step 1: Determine which color is currently LIVE ───────────────────────────
CURRENT_TG_ARN="$(aws elbv2 describe-listeners \
  --listener-arns "${MAIN_LISTENER_ARN}" \
  --region "${AWS_REGION}" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text)"

if [[ "${CURRENT_TG_ARN}" == "${TG_BLUE_ARN}" ]]; then
  LIVE_COLOR="blue"
  IDLE_COLOR="green"
  IDLE_TG_ARN="${TG_GREEN_ARN}"
  IDLE_ASG="${ASG_GREEN}"
else
  LIVE_COLOR="green"
  IDLE_COLOR="blue"
  IDLE_TG_ARN="${TG_BLUE_ARN}"
  IDLE_ASG="${ASG_BLUE}"
fi

echo "==> Current LIVE color: ${LIVE_COLOR}"
echo "==> Deploying to IDLE:  ${IDLE_COLOR}"

# ── Step 2: Update idle ASG launch template with new image ───────────────────
LAUNCH_TEMPLATE_NAME="devops-a4-${IDLE_COLOR}"

LT_ID="$(aws ec2 describe-launch-templates \
  --filters "Name=launch-template-name,Values=${LAUNCH_TEMPLATE_NAME}*" \
  --region "${AWS_REGION}" \
  --query 'LaunchTemplates[0].LaunchTemplateId' \
  --output text)"

echo "==> Updating launch template ${LT_ID} with image ${IMAGE_URI}"

aws ec2 create-launch-template-version \
  --region "${AWS_REGION}" \
  --launch-template-id "${LT_ID}" \
  --source-version '$Latest' \
  --launch-template-data "{\"UserData\":\"$(echo "#!/bin/bash
apt-get install -y docker.io awscli -y
systemctl start docker
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin $(echo ${IMAGE_URI} | cut -d/ -f1)
docker pull ${IMAGE_URI}
docker stop app 2>/dev/null || true
docker rm app 2>/dev/null || true
docker run -d --name app --restart unless-stopped -p 3000:3000 ${IMAGE_URI}" | base64 -w 0)\"}"

# ── Step 3: Trigger instance refresh on idle ASG ─────────────────────────────
echo "==> Triggering instance refresh on ASG: ${IDLE_ASG}"
REFRESH_ID="$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "${IDLE_ASG}" \
  --preferences '{"MinHealthyPercentage":100}' \
  --region "${AWS_REGION}" \
  --query 'InstanceRefreshId' \
  --output text)"

echo "==> Waiting for instance refresh ${REFRESH_ID} to complete..."
while true; do
  STATUS="$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "${IDLE_ASG}" \
    --instance-refresh-ids "${REFRESH_ID}" \
    --region "${AWS_REGION}" \
    --query 'InstanceRefreshes[0].Status' \
    --output text)"
  echo "    Refresh status: ${STATUS}"
  if [[ "${STATUS}" == "Successful" ]]; then
    break
  elif [[ "${STATUS}" == "Failed" || "${STATUS}" == "Cancelled" ]]; then
    echo "ERROR: Instance refresh ${STATUS}"
    exit 1
  fi
  sleep 20
done

# ── Step 4: Wait for targets in idle TG to become healthy ────────────────────
echo "==> Waiting for targets in ${IDLE_COLOR} TG to be healthy..."
for i in $(seq 1 20); do
  UNHEALTHY="$(aws elbv2 describe-target-health \
    --target-group-arn "${IDLE_TG_ARN}" \
    --region "${AWS_REGION}" \
    --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`]' \
    --output text)"
  if [[ -z "${UNHEALTHY}" ]]; then
    echo "==> All targets healthy!"
    break
  fi
  echo "    Waiting... attempt ${i}/20"
  sleep 15
done

# ── Step 5: Smoke test via test listener ──────────────────────────────────────
ALB_DNS="$(aws elbv2 describe-load-balancers \
  --region "${AWS_REGION}" \
  --query "LoadBalancers[?contains(ListenerArns,'${MAIN_LISTENER_ARN}')].DNSName | [0]" \
  --output text 2>/dev/null || echo '')"

# Fallback: describe the listener to get the ALB ARN, then the DNS
if [[ -z "${ALB_DNS}" || "${ALB_DNS}" == "None" ]]; then
  ALB_ARN="$(aws elbv2 describe-listeners \
    --listener-arns "${TEST_LISTENER_ARN}" \
    --region "${AWS_REGION}" \
    --query 'Listeners[0].LoadBalancerArn' \
    --output text)"
  ALB_DNS="$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "${ALB_ARN}" \
    --region "${AWS_REGION}" \
    --query 'LoadBalancers[0].DNSName' \
    --output text)"
fi

echo "==> Running smoke test against http://${ALB_DNS}:8080/health"
HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
  "http://${ALB_DNS}:8080/health" || echo '000')"

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "ERROR: Smoke test FAILED (HTTP ${HTTP_CODE}). NOT switching traffic."
  # Log failure
  LOG_ENTRY="{\"timestamp\":\"${TIMESTAMP}\",\"sha\":\"${GIT_SHA}\",\"image\":\"${IMAGE_URI}\",\"previous_color\":\"${LIVE_COLOR}\",\"new_color\":\"${IDLE_COLOR}\",\"result\":\"failed\"}"
  echo "${LOG_ENTRY}" | aws s3 cp - "s3://${DEPLOY_LOG_BUCKET}/deploy-log.jsonl" \
    --region "${AWS_REGION}" \
    --content-type "application/json" \
    --sse aws:kms 2>/dev/null || echo "${LOG_ENTRY}" >> /tmp/deploy-log.jsonl
  exit 1
fi

echo "==> Smoke test PASSED (HTTP 200)"

# ── Step 6: Switch main listener to idle TG ───────────────────────────────────
echo "==> Switching ALB listener to ${IDLE_COLOR} target group"
aws elbv2 modify-listener \
  --listener-arn "${MAIN_LISTENER_ARN}" \
  --region "${AWS_REGION}" \
  --default-actions "Type=forward,TargetGroupArn=${IDLE_TG_ARN}"

# Also point test listener at the now-idle (previously live) color
aws elbv2 modify-listener \
  --listener-arn "${TEST_LISTENER_ARN}" \
  --region "${AWS_REGION}" \
  --default-actions "Type=forward,TargetGroupArn=${CURRENT_TG_ARN}"

echo "==> Traffic switched: ${IDLE_COLOR} is now LIVE"

# ── Step 7: Append to deployment log in S3 ───────────────────────────────────
LOG_ENTRY="{\"timestamp\":\"${TIMESTAMP}\",\"sha\":\"${GIT_SHA}\",\"image\":\"${IMAGE_URI}\",\"previous_color\":\"${LIVE_COLOR}\",\"new_color\":\"${IDLE_COLOR}\",\"result\":\"success\"}"

# Download existing log, append, re-upload
aws s3 cp "s3://${DEPLOY_LOG_BUCKET}/deploy-log.jsonl" /tmp/deploy-log.jsonl \
  --region "${AWS_REGION}" 2>/dev/null || touch /tmp/deploy-log.jsonl
echo "${LOG_ENTRY}" >> /tmp/deploy-log.jsonl
aws s3 cp /tmp/deploy-log.jsonl "s3://${DEPLOY_LOG_BUCKET}/deploy-log.jsonl" \
  --region "${AWS_REGION}"

echo "==> Deployment complete. ${IDLE_COLOR} is now serving production traffic."
