# Assignment 4 – CI/CD Pipelines with Jenkins and Groovy

> **Prerequisite:** Assignment 3 infrastructure must be deployed and the S3 state bucket `tf-state-devops-a3-b1ee2f22` must exist before running any Terraform in this assignment.

---

## Folder Structure

```
assignment-4/
├── Jenkinsfile                         # Task 2 – Main declarative pipeline
├── .trivyignore                        # Task 5 – CVE suppressions
│
├── app/                                # Task 2 – Node.js sample application
│   ├── Dockerfile                      # Task 5 – Multi-stage Dockerfile
│   ├── package.json
│   ├── src/
│   │   ├── index.js
│   │   ├── app.js
│   │   └── routes.js
│   └── tests/
│       ├── unit/routes.test.js         # 6 unit tests
│       └── integration/app.test.js     # 2 integration tests
│
├── jenkins/                            # Task 1 – Jenkins setup
│   ├── plugins.txt                     # All installed plugins
│   ├── setup.md                        # Step-by-step setup guide
│   └── terraform/                      # Controller + Agent EC2
│       ├── main.tf
│       ├── data.tf
│       ├── ec2.tf
│       ├── security_groups.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── shared-library/                     # Task 3 – Groovy Shared Library
│   ├── README.md
│   ├── src/org/devops/
│   │   ├── NotificationService.groovy
│   │   └── DockerHelper.groovy
│   └── vars/
│       ├── notifySlack.groovy
│       ├── buildAndPushImage.groovy
│       └── runSonarScan.groovy
│
├── sonarqube/terraform/                # Task 4 – SonarQube EC2
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
├── ecr/terraform/                      # Task 5 – ECR + IAM role
│   ├── main.tf
│   └── variables.tf
│
├── pipelines/
│   ├── infra-pipeline/
│   │   └── Jenkinsfile                 # Task 6 – Terraform CI/CD
│   ├── rollback/
│   │   └── Jenkinsfile                 # Task 7 – Manual rollback
│   └── scripts/
│       └── blue_green_deploy.sh        # Task 7 – Deploy script
│
└── blue-green/terraform/               # Task 7 – Blue-Green infrastructure
    ├── main.tf
    └── variables.tf
```

---

## Prerequisites

| Tool       | Version  |
|------------|----------|
| Terraform  | >= 1.5   |
| AWS CLI    | >= 2.0   |
| Node.js    | >= 20    |
| Docker     | >= 24    |

---

## Deployment Order

### Step 1 – Deploy Jenkins (Task 1)
```bash
cd assignment-4/jenkins/terraform
# Update my_ip in terraform.tfvars
terraform init
terraform apply -auto-approve
# → Note jenkins_url and jenkins_agent_private_ip from output
```

### Step 2 – Deploy SonarQube (Task 4)
```bash
cd assignment-4/sonarqube/terraform
terraform init
terraform apply -auto-approve
# → Open SonarQube at the output URL, generate a token, add to Jenkins credentials
```

### Step 3 – Deploy ECR (Task 5)
```bash
cd assignment-4/ecr/terraform
terraform init
terraform apply -auto-approve
# → Note ecr_repository_url, add as Jenkins credential 'ecr-registry-url'
```

### Step 4 – Deploy Blue-Green Infrastructure (Task 7)
```bash
cd assignment-4/blue-green/terraform
# Set ecr_registry in terraform.tfvars
terraform init
terraform apply -auto-approve
```

### Step 5 – Configure Jenkins
See `jenkins/setup.md` for detailed steps including:
- Registering the shared library
- Creating all credentials
- Setting up the Multibranch Pipeline
- Configuring SonarQube

---

## Running Pipelines

| Pipeline         | How to Trigger                                    |
|------------------|---------------------------------------------------|
| Main app         | Push to any branch (GitHub webhook triggers it)   |
| infra-pipeline   | Manual — choose ACTION and AUTO_APPROVE            |
| rollback         | Manual — run from Jenkins UI when needed          |

---

## Tearing Down

```bash
# Destroy in reverse order
cd assignment-4/blue-green/terraform  && terraform destroy -auto-approve
cd assignment-4/ecr/terraform         && terraform destroy -auto-approve
cd assignment-4/sonarqube/terraform   && terraform destroy -auto-approve
cd assignment-4/jenkins/terraform     && terraform destroy -auto-approve
cd environments/main                  && terraform destroy -auto-approve
```

---

## Member Contributions

| Task | Description                              | Member              |
|------|------------------------------------------|---------------------|
| 1    | Jenkins Controller + Agent Terraform     | Ibrahim Liaqat      |
| 2    | Declarative Pipeline + Node.js App       | Ahtesham Shah       |
| 3    | Groovy Shared Library                    | Ahtesham Shah       |
| 4    | SonarQube Integration                    | Ibrahim Liaqat      |
| 5    | Dockerfile + Trivy + ECR                 | Ahtesham Shah       |
| 6    | Terraform CI/CD Pipeline                 | Ibrahim Liaqat      |
| 7    | Blue-Green Deployment + Rollback         | Both                |
