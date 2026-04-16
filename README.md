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
│   └── main/           # Root Terraform configuration
├── modules/
│   ├── vpc/            # Reusable VPC module
│   ├── compute/        # Reusable EC2 module
│   └── security/       # Reusable Security Groups module
└── packer/             # Packer template for custom AMI
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Packer](https://developer.hashicorp.com/packer/downloads) >= 1.9.0 (Task 6 only)
- AWS CLI configured with credentials (`aws configure`)
- An AWS account with appropriate IAM permissions

## Quick Start

### 1. Configure your variables

```bash
cd environments/main
```

Edit `terraform.tfvars` and set:
- `my_ip` → your public IP (run `curl ifconfig.me`)
- `ami_id` → correct Ubuntu 22.04 AMI for your region
- `region` → your target AWS region

### 2. Initialize and Apply (Two-Step for S3 Backend)

**Step 1 — Create infrastructure (local state):**
```bash
terraform init
terraform plan
terraform apply
```

**Step 2 — Migrate state to S3 (after bucket is created):**

1. Note the `s3_bucket_name` from Terraform output
2. Open `backend.tf`, uncomment the `terraform {}` block, and replace `REPLACE_WITH_OUTPUT_s3_bucket_name` with the actual bucket name
3. Run:
```bash
terraform init -migrate-state
```

### 3. Destroy all resources

```bash
terraform destroy
```

## Git Workflow

- One branch per task group
- `22F-3627` → Tasks 1–3
- `22F-3677` → Tasks 4–6
- Merge to `main` via Pull Requests

## Important Notes

- **Never commit** `.pem` key files, `.terraform/` directories, or real credentials
- The `terraform.tfvars` file contains non-sensitive defaults; update `my_ip` before applying
- SSH into the private (DB) instance via the public (Web) instance as a bastion host
