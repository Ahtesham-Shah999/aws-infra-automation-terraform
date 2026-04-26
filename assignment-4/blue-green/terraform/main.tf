# ─────────────────────────────────────────────────────────────────────────────
# Task 7 – Blue-Green Deployment: Two ASGs behind one ALB
# This extends environments/main – uses the same VPC, SGs, and key pair.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket         = "tf-state-devops-a3-b1ee2f22"
    key            = "terraform/state/blue-green.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-a3-terraform-lock"
    encrypt        = true
  }
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

# ── Pull base infrastructure from Assignment 3 ────────────────────────────────
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

# ── Target Groups ─────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "blue" {
  name     = "devops-a4-tg-blue"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.a3.outputs.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "tg-blue", Color = "blue" }
}

resource "aws_lb_target_group" "green" {
  name     = "devops-a4-tg-green"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.a3.outputs.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "tg-green", Color = "green" }
}

# ── ALB + Listeners ───────────────────────────────────────────────────────────
resource "aws_lb" "bg" {
  name               = "devops-a4-bg-alb"
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.a3.outputs.alb_sg_id]
  subnets            = data.terraform_remote_state.a3.outputs.public_subnet_ids

  tags = { Name = "devops-a4-bg-alb" }
}

# Main listener — starts forwarding to BLUE (initial live color)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.bg.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# Test listener on port 8080 — used by smoke tests to probe the idle color
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.bg.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn  # points to idle initially
  }
}

# ── Launch Templates ──────────────────────────────────────────────────────────
resource "aws_launch_template" "blue" {
  name_prefix   = "devops-a4-blue-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [data.terraform_remote_state.a3.outputs.web_sg_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
apt-get update -y
apt-get install -y docker.io awscli
systemctl start docker
$(aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_registry})
docker pull ${var.ecr_registry}/devops-a4-app:blue 2>/dev/null || \
  docker pull ${var.ecr_registry}/devops-a4-app:latest
docker run -d --name app --restart unless-stopped -p 3000:3000 \
  ${var.ecr_registry}/devops-a4-app:blue 2>/dev/null || \
  docker run -d --name app --restart unless-stopped -p 3000:3000 \
  ${var.ecr_registry}/devops-a4-app:latest
EOF
  )

  tags = { Name = "devops-a4-blue" }
}

resource "aws_launch_template" "green" {
  name_prefix   = "devops-a4-green-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [data.terraform_remote_state.a3.outputs.web_sg_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
apt-get update -y
apt-get install -y docker.io awscli
systemctl start docker
$(aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_registry})
docker pull ${var.ecr_registry}/devops-a4-app:green 2>/dev/null || \
  docker pull ${var.ecr_registry}/devops-a4-app:latest
docker run -d --name app --restart unless-stopped -p 3000:3000 \
  ${var.ecr_registry}/devops-a4-app:green 2>/dev/null || \
  docker run -d --name app --restart unless-stopped -p 3000:3000 \
  ${var.ecr_registry}/devops-a4-app:latest
EOF
  )

  tags = { Name = "devops-a4-green" }
}

# ── Auto Scaling Groups ───────────────────────────────────────────────────────
resource "aws_autoscaling_group" "blue" {
  name                = "asg-blue"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = data.terraform_remote_state.a3.outputs.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.blue.arn]

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-blue-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Color"
    value               = "blue"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "asg-green"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = data.terraform_remote_state.a3.outputs.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.green.arn]

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-green-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Color"
    value               = "green"
    propagate_at_launch = true
  }
}

# ── S3 Deployment Log Bucket ──────────────────────────────────────────────────
resource "aws_s3_bucket" "deploy_log" {
  bucket        = "devops-a4-deploy-log-${random_id.suffix.hex}"
  force_destroy = true
  tags          = { Name = "deploy-log" }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "alb_dns_name" {
  value = aws_lb.bg.dns_name
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "main_listener_arn" {
  value = aws_lb_listener.main.arn
}

output "test_listener_arn" {
  value = aws_lb_listener.test.arn
}

output "deploy_log_bucket" {
  value = aws_s3_bucket.deploy_log.id
}

output "blue_asg_name" {
  value = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  value = aws_autoscaling_group.green.name
}
