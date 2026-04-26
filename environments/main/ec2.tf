# ─────────────────────────────────────────────────────────────────────────────
# Task 2 — EC2 Instances (Web Server + DB Server)
# Member: 22F-3627
# ─────────────────────────────────────────────────────────────────────────────

# ── User-data: installs Nginx and displays the instance ID ────────────────────
locals {
  web_user_data = <<-USERDATA
#!/bin/bash
# Do NOT use set -e — we want nginx to start even if earlier steps warn/fail
exec > /var/log/user-data.log 2>&1
apt-get update -y
apt-get install -y nginx
apt-get install php 8.1
sleep 2
INSTANCE_ID=$(curl -s --retry 3 --retry-delay 2 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>DevOps Assignment 3</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Segoe UI', Arial, sans-serif;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}
.card {
  background: rgba(255,255,255,0.05);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 16px;
  padding: 48px 64px;
  text-align: center;
  color: #fff;
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}
h1 { font-size: 2rem; margin-bottom: 8px; }
.sub { color: #a0aec0; margin-bottom: 24px; }
.badge {
  display: inline-block;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 1.2rem;
  font-weight: bold;
  padding: 12px 32px;
  border-radius: 50px;
  letter-spacing: 1px;
}
.footer { margin-top: 24px; color: #718096; font-size: 0.85rem; }
</style>
</head>
<body>
<div class="card">
<h1>&#9749; DevOps Assignment 3</h1>
<p class="sub">Provisioned with Terraform on AWS</p>
<div class="badge">$INSTANCE_ID</div>
<p class="footer">Web Server &mdash; Public Subnet</p>
</div>
</body>
</html>
HTML

systemctl start nginx
systemctl enable nginx
USERDATA
}

# ── Public Web Server ─────────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.main.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_profile.name
  associate_public_ip_address = true

  user_data = base64encode(replace(local.web_user_data, "\r\n", "\n"))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-web-server"
    Role = "WebServer"
  }
}

# ── Private Database Server ───────────────────────────────────────────────────
resource "aws_instance" "db" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.db.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-db-server"
    Role = "DatabaseServer"
  }
}
