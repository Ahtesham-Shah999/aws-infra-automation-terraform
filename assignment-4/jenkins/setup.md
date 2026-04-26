# Jenkins Controller and Agent Setup Guide

## Prerequisites
- AWS credentials configured
- Terraform installed
- The `devops-a3-key.pem` SSH key from Assignment 3
- Assignment 3 infrastructure already deployed (S3 state bucket must exist)

## Step 1 – Deploy the EC2 Instances

```bash
cd assignment-4/jenkins/terraform

# Update my_ip in terraform.tfvars with your current IP
curl ifconfig.me  # use this value + /32

terraform init
terraform apply -auto-approve
```

After apply completes, note the outputs:
- `jenkins_controller_ip` — the public IP to access Jenkins
- `jenkins_agent_private_ip` — the private IP used when registering the agent

## Step 2 – Access Jenkins for the First Time

1. Wait ~5 minutes for the `user_data` script to finish installing Jenkins.
2. Open your browser and navigate to: `http://<jenkins_controller_ip>:8080`
3. SSH in to retrieve the initial admin password:
   ```bash
   ssh -i devops-a3-key.pem ubuntu@<jenkins_controller_ip>
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
4. Paste the password into the web wizard.
5. Click **Install suggested plugins**.
6. Create your admin user (do **not** keep the default password).
7. Set the Jenkins URL to `http://<jenkins_controller_ip>:8080`.

## Step 3 – Install Required Plugins

Go to **Manage Jenkins → Plugins → Available plugins** and search for/install:
- Pipeline
- Git
- GitHub Branch Source
- Docker Pipeline
- Credentials Binding
- Pipeline Utility Steps
- SonarQube Scanner
- Blue Ocean
- Slack Notification

## Step 4 – Add Credentials (Manage Jenkins → Credentials → Global)

| ID                     | Type                | Description                         |
|------------------------|---------------------|-------------------------------------|
| `aws-access-key`       | AWS Credentials     | AWS Access Key ID + Secret          |
| `github-pat`           | Username/password   | GitHub username + Personal Token    |
| `sonarqube-token`      | Secret text         | SonarQube project token (Task 4)    |
| `ecr-credentials`      | Username/password   | AWS ECR Docker credentials          |
| `slack-webhook`        | Secret text         | Slack incoming webhook URL          |

## Step 5 – Register the Build Agent

1. Go to **Manage Jenkins → Nodes → New Node**.
2. Name: `linux-agent`, type: **Permanent Agent**, click OK.
3. Set:
   - **Remote root directory**: `/home/ubuntu/jenkins`
   - **Labels**: `linux-agent`
   - **Launch method**: Launch via SSH
   - **Host**: `<jenkins_agent_private_ip>` (from terraform output)
   - **Credentials**: add the `devops-a3-key.pem` as SSH private key
   - **Host Key Verification**: Non-verifying
4. Save. The agent status should turn green within 30 seconds.

## Step 6 – Configure GitHub Plugin

1. **Manage Jenkins → System → GitHub Servers → Add**.
2. Set credentials to your `github-pat`.
3. Click **Test connection** — it should say "Credentials verified".

## Step 7 – Sanity Check

Create a **Pipeline** job named `sanity-check` with this script:

```groovy
pipeline {
    agent { label 'linux-agent' }
    stages {
        stage('Hello') {
            steps {
                echo 'hello'
            }
        }
    }
}
```

Click **Build Now** — it should succeed on the agent.
