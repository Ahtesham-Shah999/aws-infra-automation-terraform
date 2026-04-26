terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── ECR Repository ────────────────────────────────────────────────────────────
resource "aws_ecr_repository" "app" {
  name                 = "devops-a4-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "devops-a4-app"
    ManagedBy = "Terraform"
  }
}

# ── Lifecycle Policy ──────────────────────────────────────────────────────────
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the 10 most recent tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["main", "develop", "v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ── IAM Role for Jenkins Agent (ECR push without long-lived keys) ─────────────
resource "aws_iam_role" "jenkins_agent" {
  name = "jenkins-agent-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "jenkins-agent-ecr-role" }
}

resource "aws_iam_policy" "agent_ecr_policy" {
  name        = "jenkins-agent-ecr-policy"
  description = "Allow Jenkins agent to push/pull ECR images"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_ecr_attach" {
  role       = aws_iam_role.jenkins_agent.name
  policy_arn = aws_iam_policy.agent_ecr_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_agent" {
  name = "jenkins-agent-profile"
  role = aws_iam_role.jenkins_agent.name
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "ecr_repository_url" {
  description = "ECR repository URL — set this as ECR_REGISTRY in Jenkins"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.app.arn
}
