# ─────────────────────────────────────────────────────────────────────────────
# modules-demo/terraform.tfvars
# Update my_ip before running: curl ifconfig.me
# ─────────────────────────────────────────────────────────────────────────────

region       = "us-east-1"
environment  = "dev"
project_name = "devops-a3"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# EC2
# Ubuntu 22.04 LTS (Jammy) — us-east-1. Update for other regions.
ami_id        = "ami-0c7217cdde317cfec"
instance_type = "t3.micro"
key_name      = "devops-a3-modules-key"

# ⚠️  REQUIRED: Replace with YOUR actual public IP (run: curl ifconfig.me)
my_ip = "59.103.246.18"
