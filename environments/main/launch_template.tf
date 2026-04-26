# ─────────────────────────────────────────────────────────────────────────────
# Task 4 — Launch Template for Auto Scaling Group
# Member: 22F-3677
# ─────────────────────────────────────────────────────────────────────────────

locals {
  asg_user_data = <<-USERDATA
#!/bin/bash
# Do NOT use set -e — we want nginx to start even if earlier steps warn/fail
exec > /var/log/user-data.log 2>&1

apt-get update -y
apt-get install -y nginx stress-ng

# Wait briefly for metadata service to be ready
sleep 2
INSTANCE_ID=$(curl -s --retry 3 --retry-delay 2 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DevOps A3 - ASG Instance</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: rgba(255,255,255,0.07);
      border: 1px solid rgba(255,255,255,0.12);
      border-radius: 16px;
      padding: 48px 64px;
      text-align: center;
      color: #fff;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    }
    h1 { font-size: 1.8rem; margin-bottom: 8px; }
    .sub { color: #90cdf4; margin-bottom: 24px; font-size: 0.95rem; }
    .badge {
      display: inline-block;
      background: linear-gradient(135deg, #f093fb, #f5576c);
      color: #fff;
      font-size: 1.1rem;
      font-weight: bold;
      padding: 10px 28px;
      border-radius: 50px;
    }
    .note { margin-top: 20px; color: #cbd5e0; font-size: 0.85rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>&#9889; Auto-Scaled Instance</h1>
    <p class="sub">Managed by AWS Auto Scaling Group</p>
    <div class="badge">$INSTANCE_ID</div>
    <p class="note">stress-ng installed &mdash; use it to trigger scale-out</p>
  </div>
</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx
systemctl restart nginx
USERDATA
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  user_data = base64encode(replace(local.asg_user_data, "\r\n", "\n"))

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-asg-instance"
      Environment = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }

  lifecycle {
    create_before_destroy = true
  }
}
