# ─────────────────────────────────────────────────────────────────────────────
# Task 6 — modules-demo: Outputs
# Member: 22F-3677
# ─────────────────────────────────────────────────────────────────────────────

# ── VPC Module Outputs ────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID (sourced from module.vpc)"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (sourced from module.vpc)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (sourced from module.vpc)"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (sourced from module.vpc)"
  value       = module.vpc.nat_gateway_id
}

# ── Security Module Outputs ───────────────────────────────────────────────────
output "web_sg_id" {
  description = "Web server Security Group ID (sourced from module.security)"
  value       = module.security.web_sg_id
}

output "db_sg_id" {
  description = "DB server Security Group ID (sourced from module.security)"
  value       = module.security.db_sg_id
}

output "alb_sg_id" {
  description = "ALB Security Group ID (sourced from module.security)"
  value       = module.security.alb_sg_id
}

# ── Compute Module Outputs ────────────────────────────────────────────────────
output "web_instance_id" {
  description = "Web server instance ID (sourced from module.web)"
  value       = module.web.instance_id
}

output "web_public_ip" {
  description = "Web server public IP (sourced from module.web)"
  value       = module.web.public_ip
}

output "db_instance_id" {
  description = "DB server instance ID (sourced from module.db)"
  value       = module.db.instance_id
}

output "db_private_ip" {
  description = "DB server private IP (sourced from module.db)"
  value       = module.db.private_ip
}

# ── SSH helper commands ───────────────────────────────────────────────────────
output "ssh_web_cmd" {
  description = "SSH into web server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${module.web.public_ip}"
}

output "ssh_db_via_bastion_cmd" {
  description = "SSH into DB server via web server (bastion pattern)"
  value       = "ssh -i ${var.key_name}.pem -J ubuntu@${module.web.public_ip} ubuntu@${module.db.private_ip}"
}
