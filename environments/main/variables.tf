# ─── General ───────────────────────────────────────────────────────────────────

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devops-a3"
}

# ─── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# ─── EC2 / ASG ─────────────────────────────────────────────────────────────────

variable "ami_id" {
  description = "AMI ID for EC2 instances. Default: Ubuntu 22.04 LTS in us-east-1"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "instance_type" {
  description = "EC2 instance type (must be t3.micro, t3.small, or t3.medium)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "instance_type must be one of: t3.micro, t3.small, t3.medium."
  }
}

variable "key_name" {
  description = "Name for the SSH key pair resource"
  type        = string
  default     = "devops-a3-key"
}

variable "my_ip" {
  description = "Your public IP address for SSH access (without /32). Run: curl ifconfig.me"
  type        = string
  default     = "0.0.0.0"
}

# ─── S3 / Backend ──────────────────────────────────────────────────────────────

variable "s3_bucket_prefix" {
  description = "Prefix for the Terraform state S3 bucket name"
  type        = string
  default     = "tf-state"
}
