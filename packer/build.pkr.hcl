# ─────────────────────────────────────────────────────────────────────────────
# Packer Template — Custom Ubuntu AMI with Nginx, curl, stress-ng
# Task 6 | Member: 22F-3677
#
# Usage:
#   packer init build.pkr.hcl
#   packer build build.pkr.hcl
#
# Prerequisites:
#   - Packer >= 1.9.0  (https://developer.hashicorp.com/packer/downloads)
#   - AWS credentials configured (aws configure or env vars)
#   - IAM permissions: ec2:RunInstances, ec2:CreateImage, etc.
# ─────────────────────────────────────────────────────────────────────────────

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# ── Input Variables ───────────────────────────────────────────────────────────
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to build the AMI in"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type used during the build"
}

# ── Source AMI: latest Ubuntu 22.04 LTS (Canonical) ─────────────────────────
data "amazon-ami" "ubuntu_22_04" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"] # Canonical official account
  region      = var.aws_region
}

# ── Build Source ──────────────────────────────────────────────────────────────
source "amazon-ebs" "ubuntu" {
  ami_name      = "devops-a3-custom-ami-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.ubuntu_22_04.id
  ssh_username  = "ubuntu"

  ami_description = "DevOps Assignment 3 — Custom AMI with Nginx, curl, stress-ng"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name        = "devops-a3-custom-ami"
    Environment = "dev"
    Builder     = "Packer"
    BaseAMI     = data.amazon-ami.ubuntu_22_04.id
    Project     = "devops-assignment3"
  }
}

# ── Build Steps ───────────────────────────────────────────────────────────────
build {
  name    = "devops-a3-custom-ami"
  sources = ["source.amazon-ebs.ubuntu"]

  # 1. Update & upgrade packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
    ]
  }

  # 2. Install required tools
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y nginx curl stress-ng",
      "sudo systemctl enable nginx"
    ]
  }

  # 3. Create custom welcome page
  provisioner "shell" {
    inline = [
      "sudo python3 -c \"\nimport textwrap\nhtml = textwrap.dedent('''\n<!DOCTYPE html>\n<html lang=\\\"en\\\">\n<head>\n  <meta charset=\\\"UTF-8\\\">\n  <title>DevOps Assignment 3 - Custom AMI</title>\n  <style>\n    *{box-sizing:border-box;margin:0;padding:0}\n    body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh;display:flex;align-items:center;justify-content:center}\n    .card{background:rgba(255,255,255,.95);border-radius:16px;padding:48px 64px;text-align:center;box-shadow:0 8px 32px rgba(0,0,0,.3)}\n    h1{color:#2d3748;font-size:2rem;margin-bottom:12px}\n    .badge{background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;padding:8px 24px;border-radius:50px;font-size:.9rem;display:inline-block;margin:8px 0}\n    p{color:#4a5568;margin-top:16px}\n  </style>\n</head>\n<body>\n  <div class=\\\"card\\\">\n    <h1>DevOps Assignment 3</h1>\n    <div class=\\\"badge\\\">Custom Packer AMI</div>\n    <div class=\\\"badge\\\">Nginx | curl | stress-ng</div>\n    <p>Built automatically with HashiCorp Packer</p>\n  </div>\n</body>\n</html>\n''')\nopen('/tmp/index.html','w').write(html)\n\"",
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo chown www-data:www-data /var/www/html/index.html"
    ]
  }

  # 4. Verify all tools installed correctly
  provisioner "shell" {
    inline = [
      "echo '=== Verifying installed tools ==='",
      "nginx -v",
      "curl --version | head -1",
      "stress-ng --version",
      "echo '=== All tools verified successfully ==='"
    ]
  }
}
