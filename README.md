# AWS Infrastructure Automation with Terraform

A complete AWS infrastructure provisioned entirely via Terraform — no manual AWS Console steps.

## Team Members & Contributions

| Roll Number | Tasks |
|-------------|-------|
| 22F-3627 | Task 1 (VPC + NAT Gateway), Task 2 (Security Groups + EC2), Task 3 (S3 + Remote State) |
| 22F-3677 | Task 4 (Auto Scaling + CloudWatch), Task 5 (ALB + Health Checks), Task 6 (Modules + Packer) |

## Project Structure

```
.
├── environments/
│   ├── main/               # Root Terraform configuration (Tasks 1–5)
│   │   ├── vpc.tf          # Task 1: VPC, subnets, IGW, NAT, route tables
│   │   ├── security_groups.tf  # Task 2: ALB, web, and DB security groups
│   │   ├── ec2.tf          # Task 2: Public web server + private DB server
│   │   ├── key_pair.tf     # Task 2: SSH key pair (RSA-4096)
│   │   ├── s3.tf           # Task 3: S3 bucket (versioning, encryption, block public)
│   │   ├── iam.tf          # Task 3: IAM role + policy for EC2 → S3
│   │   ├── dynamodb.tf     # Task 3: DynamoDB state-lock table
│   │   ├── backend.tf      # Task 3: S3 remote backend configuration
│   │   ├── launch_template.tf  # Task 4: Launch template with stress-ng
│   │   ├── autoscaling.tf  # Task 4: ASG + scale-out/in policies
│   │   ├── cloudwatch.tf   # Task 4: CPU high/low alarms
│   │   ├── alb.tf          # Task 5: ALB, target group, listener, ASG attachment
│   │   ├── providers.tf    # Provider + required_providers
│   │   ├── variables.tf    # All input variable definitions
│   │   ├── terraform.tfvars # Variable values (update my_ip!)
│   │   └── outputs.tf      # All resource outputs
│   └── modules-demo/       # Task 6: Demonstrates calling all reusable modules
│       ├── main.tf         # Calls module.vpc, module.security, module.web, module.db
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── terraform.tfvars
├── modules/
│   ├── vpc/                # Task 6: Reusable VPC module
│   ├── compute/            # Task 6: Reusable EC2 compute module
│   └── security/           # Task 6: Reusable Security Groups module
└── packer/
    └── build.pkr.hcl       # Task 6: Packer template for custom AMI
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Packer](https://developer.hashicorp.com/packer/downloads) >= 1.9.0 (Task 6 only)
- AWS CLI configured with credentials (`aws configure`)
- An AWS account with appropriate IAM permissions

---

## Task 1–5: Main Environment

### 1. Configure variables

```bash
cd environments/main
```

Edit `terraform.tfvars` and set:
- `my_ip` → your public IP (run `curl ifconfig.me`)
- `ami_id` → correct Ubuntu 22.04 AMI for your region
- `region` → your target AWS region

### 2. Initialize and Apply (Two-Step for S3 Backend)

**Step 1 — Create infrastructure with local state:**
```bash
terraform init
terraform plan
terraform apply
```

Note the `s3_bucket_name` value from the Terraform output.

**Step 2 — Migrate state to S3:**

Open `backend.tf`, replace the `bucket` value with the output from Step 1, then run:
```bash
terraform init -migrate-state
```

Confirm `yes` to migrate the local state file into S3. After migration:
- The `.tfstate` file lives in the S3 bucket
- All state operations are locked via DynamoDB

### 3. Destroy all resources

```bash
terraform destroy
```

---

## Task 6: Modules Demo

The `environments/modules-demo/` directory demonstrates how the three reusable
modules (`modules/vpc`, `modules/security`, `modules/compute`) are called from
a root `main.tf` using cross-module references.

```bash
cd environments/modules-demo

# Update my_ip in terraform.tfvars first
terraform init
terraform plan
terraform apply
terraform destroy
```

Key cross-module references in `main.tf`:
- `module.vpc.vpc_id` → passed to `module.security`
- `module.vpc.public_subnet_ids[0]` → passed to `module.web`
- `module.vpc.private_subnet_ids[0]` → passed to `module.db`
- `module.security.web_sg_id` → passed to `module.web`
- `module.security.db_sg_id` → passed to `module.db`

---

## Task 6: Packer Custom AMI

```bash
cd packer
packer init build.pkr.hcl
packer build build.pkr.hcl
```

The resulting AMI (with Nginx, curl, and stress-ng pre-installed) will appear
under EC2 → AMIs in the AWS Console. Copy the AMI ID and set it as `ami_id`
in your `terraform.tfvars`.

---

## Git Workflow

- One branch per task group
- `22F-3627` → Tasks 1–3
- `22F-3677` → Tasks 4–6
- Merge to `main` via Pull Requests

## Important Notes

- **Never commit** `.pem` key files, `.terraform/` directories, or real credentials
- The `terraform.tfvars` files contain non-sensitive defaults; update `my_ip` before applying
- SSH into the private (DB) instance via the public (Web) instance as a bastion host:
  ```bash
  ssh -i devops-a3-key.pem -J ubuntu@<web-public-ip> ubuntu@<db-private-ip>
  ```
