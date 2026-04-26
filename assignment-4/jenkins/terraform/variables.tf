variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "my_ip" {
  description = "Your IP address (with /32) for accessing Jenkins"
  type        = string
}

variable "key_name" {
  description = "Name of the existing EC2 key pair from Assignment 3"
  type        = string
  default     = "devops-a3-key"
}
