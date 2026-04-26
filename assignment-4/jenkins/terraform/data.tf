# Fetch the VPC and subnets from Assignment 3's remote state
data "terraform_remote_state" "a3" {
  backend = "s3"
  config = {
    bucket = "tf-state-devops-a3-b1ee2f22"
    key    = "terraform/state/terraform.tfstate"
    region = "us-east-1"
  }
}

# Fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
