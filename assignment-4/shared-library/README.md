# DevOps Shared Library

Reusable Jenkins Shared Library for Assignment 4 CI/CD pipelines.

## Repository Structure

```
.
├── src/
│   └── org/
│       └── devops/
│           ├── NotificationService.groovy  # Slack + Email notifications
│           └── DockerHelper.groovy         # Docker build + ECR push
└── vars/
    ├── notifySlack.groovy         # Global step for Slack
    ├── buildAndPushImage.groovy   # Global step for Docker + ECR
    └── runSonarScan.groovy        # Global step for SonarQube
```

## Registering in Jenkins

1. Go to **Manage Jenkins → System → Global Pipeline Libraries**
2. Click **Add** and set:
   - **Name**: `devops-shared-lib`
   - **Default version**: `main`
   - **Load implicitly**: ❌ disabled
   - **SCM**: Git — set the URL to this repository

## Classes

### `NotificationService`
Provides `sendSlack(message, color)` and `sendEmail(to, subject, body)`.

**Constructor**: `new NotificationService(this)` — pass the Jenkins pipeline script.

```groovy
import org.devops.NotificationService
def n = new NotificationService(this)
n.sendSlack('Hello from Jenkins!', 'good')
```

### `DockerHelper`
Provides `buildImage(name, sha, branch, context)` and `pushImage(name, sha, branch, registry)`.

```groovy
import org.devops.DockerHelper
def d = new DockerHelper(this)
d.buildImage('myapp', 'abc1234', 'main', '.')
d.pushImage('myapp', 'abc1234', 'main', '123456789.dkr.ecr.us-east-1.amazonaws.com')
```

## Global Steps (vars)

### `notifySlack`
```groovy
@Library('devops-shared-lib') _
notifySlack(message: '✅ Build passed!', color: 'good')
```
**Required**: `message`. Optional: `color` (default `good`), `credentialsId` (default `slack-webhook`).

### `buildAndPushImage`
```groovy
buildAndPushImage(
    name      : 'devops-a4-app',
    sha       : env.GIT_SHA,
    branch    : env.BRANCH_NAME_CLEAN,
    registry  : env.ECR_REGISTRY,
    awsCredsId: 'aws-access-key',
    region    : 'us-east-1',
    context   : 'assignment-4/app'
)
```
**Required**: `name`, `sha`, `branch`, `registry`, `awsCredsId`.

### `runSonarScan`
```groovy
runSonarScan(
    projectKey    : 'devops-a4-app',
    sources       : 'src',
    tests         : 'tests',
    coverageReport: 'coverage/lcov.info'
)
```
**Required**: `projectKey`.
