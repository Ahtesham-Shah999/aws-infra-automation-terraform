# ─────────────────────────────────────────────────────────────────────────────
# Module: compute — single EC2 instance with Nginx user-data
# Task 6 | Member: 22F-3677
# ─────────────────────────────────────────────────────────────────────────────

locals {
  user_data_script = <<-USERDATA
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx curl

    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>${var.project_name} | ${var.environment}</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 60px;
               background: #f7fafc; }
        .card { background: #fff; border-radius: 12px; padding: 40px;
                display: inline-block; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        h1 { color: #2d3748; }
        .id { font-size: 1.3em; color: #4a5568; font-weight: bold; margin: 16px 0; }
        .tag { background: #667eea; color: #fff; padding: 4px 12px;
               border-radius: 20px; font-size: 0.85em; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>${var.project_name}</h1>
        <p class="id">$INSTANCE_ID</p>
        <span class="tag">${var.environment} &mdash; ${var.role}</span>
      </div>
    </body>
    </html>
HTML

    systemctl start nginx
    systemctl enable nginx
  USERDATA
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip
  iam_instance_profile        = var.instance_profile_name != "" ? var.instance_profile_name : null

  user_data = base64encode(local.user_data_script)

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.role}"
    Environment = var.environment
    Role        = var.role
  }
}
