# ─────────────────────────────────────────────────────────────────────────────
# Task 3 — S3 Remote Backend Configuration
# Member: 22F-3627
#
# HOW TO USE (two-step process):
#
# STEP 1 ─ Keep this block commented out.
#           Run:  terraform init
#                 terraform apply
#           Note the "s3_bucket_name" value from the outputs.
#
# STEP 2 ─ Uncomment the terraform {} block below.
#           Replace REPLACE_WITH_BUCKET_NAME with the actual bucket name.
#           Run:  terraform init -migrate-state
#           Confirm "yes" to migrate local state into S3.
#
# After migration, your .tfstate will live in S3 and be locked via DynamoDB.
# ─────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_WITH_BUCKET_NAME"
#     key            = "terraform/state/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "devops-a3-terraform-lock"
#     encrypt        = true
#   }
# }
