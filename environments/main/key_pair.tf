# ─────────────────────────────────────────────────────────────────────────────
# Task 2 — SSH Key Pair
# Member: 22F-3627
# ─────────────────────────────────────────────────────────────────────────────

# Generate an RSA-4096 private key locally
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key as an EC2 Key Pair in AWS
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

# Save the private key locally as a .pem file (chmod 400)
# This file is listed in .gitignore — never commit it
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}
