# ─────────────────────────────────────────────────────────────────────────────
# Task 3 — DynamoDB Table for Terraform State Locking
# Member: 22F-3627
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-terraform-lock"
    Purpose = "TerraformStateLocking"
  }
}
