# ─────────────────────────────────────────────────────────────────────────────
# Outputs — displayed after terraform apply
# ─────────────────────────────────────────────────────────────────────────────

# ── Task 1: VPC ───────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the custom VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# ── Task 2: EC2 ───────────────────────────────────────────────────────────────
output "web_server_public_ip" {
  description = "Public IP of the web server — open in browser to see Nginx page"
  value       = aws_instance.web.public_ip
}

output "web_server_public_dns" {
  description = "Public DNS of the web server"
  value       = aws_instance.web.public_dns
}

output "db_server_private_ip" {
  description = "Private IP of the database server (accessible only via bastion)"
  value       = aws_instance.db.private_ip
}

output "ssh_web_server_cmd" {
  description = "Command to SSH into the web server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.web.public_ip}"
}

output "ssh_db_via_bastion_cmd" {
  description = "Command to SSH into the DB server via the web server (bastion)"
  value       = "ssh -i ${var.key_name}.pem -J ubuntu@${aws_instance.web.public_ip} ubuntu@${aws_instance.db.private_ip}"
}

output "key_pair_name" {
  description = "Name of the EC2 Key Pair in AWS"
  value       = aws_key_pair.main.key_name
}

# ── Task 3: S3 ────────────────────────────────────────────────────────────────
output "s3_bucket_name" {
  description = "Name of the S3 bucket — use this in backend.tf after migration"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB state-lock table"
  value       = aws_dynamodb_table.terraform_lock.name
}

# ── Task 5: ALB ───────────────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — use this in your browser"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

# ── Assignment 4 helpers ───────────────────────────────────────────────────────
output "alb_sg_id" {
  description = "ID of the ALB security group (used by A4 Blue-Green)"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "ID of the Web server security group (used by A4 Blue-Green)"
  value       = aws_security_group.web.id
}
