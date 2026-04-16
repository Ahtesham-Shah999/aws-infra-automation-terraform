variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
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

variable "my_ip" {
  description = "Your public IP for SSH access (without /32)"
  type        = string
  default     = "0.0.0.0"
}
