terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── Pull VPC/SG details from Assignment 3 remote state ────────────────────────
data "terraform_remote_state" "a3" {
  backend = "s3"
  config = {
    bucket = "tf-state-devops-a3-b1ee2f22"
    key    = "terraform/state/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── Security Group ─────────────────────────────────────────────────────────────
resource "aws_security_group" "sonarqube" {
  name        = "sonarqube-sg"
  description = "Allow port 9000 from my IP and Jenkins agent SG"
  vpc_id      = data.terraform_remote_state.a3.outputs.vpc_id

  ingress {
    description = "SonarQube UI from my IP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sonarqube-sg" }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "sonarqube" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"  # SonarQube needs >1 vCPU
  subnet_id                   = data.terraform_remote_state.a3.outputs.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
apt-get update -y
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# SonarQube recommends these kernel settings
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
echo "vm.max_map_count=524288" >> /etc/sysctl.conf
echo "fs.file-max=131072"     >> /etc/sysctl.conf

docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community
EOF

  tags = { Name = "sonarqube-server" }
}

output "sonarqube_url" {
  value = "http://${aws_instance.sonarqube.public_ip}:9000"
}
