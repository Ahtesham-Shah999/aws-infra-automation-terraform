# ─────────────────────────────────────────────────────────────────────────────
# Task 3 — IAM Role + Instance Profile for EC2 → S3 Access
# Member: 22F-3627
# ─────────────────────────────────────────────────────────────────────────────

# ── IAM Role (Trust Policy for EC2) ──────────────────────────────────────────
resource "aws_iam_role" "ec2_s3_role" {
  name = "${var.project_name}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-s3-role"
  }
}

# ── IAM Policy — S3 Read/Write for this bucket ONLY ──────────────────────────
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "${var.project_name}-ec2-s3-policy"
  description = "Allows EC2 to read and write objects in the Terraform state bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}

# ── Attach Policy to Role ─────────────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# ── Instance Profile (wrapper required to attach role to EC2) ─────────────────
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "${var.project_name}-ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name

  tags = {
    Name = "${var.project_name}-ec2-s3-profile"
  }
}
