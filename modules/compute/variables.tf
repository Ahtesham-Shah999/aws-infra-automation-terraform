variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for resource names"
  type        = string
  default     = "devops-a3"
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach (leave empty to skip)"
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP address"
  type        = bool
  default     = true
}

variable "role" {
  description = "Role label for the instance (web, db, bastion, etc.)"
  type        = string
  default     = "web"
}
