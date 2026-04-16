# ─────────────────────────────────────────────────────────────────────────────
# Task 3 — S3 Bucket for Terraform State
# Member: 22F-3627
# ─────────────────────────────────────────────────────────────────────────────

# Random suffix to guarantee a globally unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3_bucket_prefix}-${var.project_name}-${random_id.bucket_suffix.hex}"

  # Prevent accidental deletion when state is stored inside
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name    = "${var.project_name}-terraform-state"
    Purpose = "TerraformStateStorage"
  }
}

# ── Versioning ────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-Side Encryption (AES-256) ─────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ── Block ALL Public Access ───────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Lifecycle: transition old state versions to cheaper storage ───────────────
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  # Must wait for versioning to be enabled first
  depends_on = [aws_s3_bucket_versioning.terraform_state]

  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
