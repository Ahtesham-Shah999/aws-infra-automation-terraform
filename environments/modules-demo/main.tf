# ─────────────────────────────────────────────────────────────────────────────
# Task 6 — modules-demo: Root main.tf
#
# This file demonstrates how all three reusable modules are called and wired
# together using cross-module references (e.g., module.vpc.vpc_id).
#
# Member: 22F-3677
# ─────────────────────────────────────────────────────────────────────────────

# ── SSH Key Pair ───────────────────────────────────────────────────────────────
# Generate an RSA key and register it with AWS so module-launched instances
# can be SSH'd into.

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

# ── Module: vpc ───────────────────────────────────────────────────────────────
# Creates the VPC, public/private subnets, IGW, EIP, NAT Gateway, and route
# tables. All other modules reference outputs from this module — the VPC and
# subnet IDs flow downward through module.vpc.*.

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
}

# ── Module: security ──────────────────────────────────────────────────────────
# Creates the ALB, web-server, and database security groups.
# Uses module.vpc.vpc_id — a cross-module reference — to scope the groups to
# the VPC that was just built.

module "security" {
  source = "../../modules/security"

  # Cross-module reference: VPC ID comes from the vpc module output
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name
  my_ip        = var.my_ip
}

# ── Module: compute (web server) ──────────────────────────────────────────────
# Launches a public EC2 instance (Nginx web server).
# Uses cross-module references for both the subnet and the security group.

module "web" {
  source = "../../modules/compute"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = aws_key_pair.main.key_name
  environment        = var.environment
  project_name       = var.project_name
  role               = "web"
  associate_public_ip = true

  # Cross-module references: subnet from vpc, sg from security
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.web_sg_id]
}

# ── Module: compute (database server) ────────────────────────────────────────
# Launches a private EC2 instance (DB server, no public IP).
# Subnet and security group both come from upstream module outputs.

module "db" {
  source = "../../modules/compute"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = aws_key_pair.main.key_name
  environment        = var.environment
  project_name       = var.project_name
  role               = "db"
  associate_public_ip = false

  # Cross-module references: private subnet from vpc, db sg from security
  subnet_id          = module.vpc.private_subnet_ids[0]
  security_group_ids = [module.security.db_sg_id]
}
