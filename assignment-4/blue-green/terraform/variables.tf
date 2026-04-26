variable "region" {
  default = "us-east-1"
}
variable "key_name" {
  default = "devops-a3-key"
}
variable "ecr_registry" {
  description = "ECR registry URL (without image name), e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com"
  type        = string
}
