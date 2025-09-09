# =================================================================
# 🎓 IAM Configuration pour projet de candidature
# Démontre les bonnes pratiques avec ARN exacts depuis shared
# =================================================================

data "aws_caller_identity" "current" {}

# Récupération des ressources depuis shared
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "my-s3-shared-backend-s-vs-c-2025"
    key    = "shared/terraform.tfstate"
    region = "eu-west-3"
  }
}

# ---------------------
# 🔐 Service Roles
# ---------------------

# Lambda Role - Principe du moindre privilège
resource "aws_iam_role" "lambda_role" {
  name = "${var.env_prefix}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose = "Service role for Lambda functions"
    Project = "architecture-comparison"
  })
}

# EC2 Role - Accès limité aux ressources nécessaires
resource "aws_iam_role" "ec2_role" {
  name = "${var.env_prefix}-ec2-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose = "Service role for EC2 instances"
    Project = "architecture-comparison"
  })
}

# Instance Profile pour EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------
# 📋 Policies - Granulaires et sécurisées
# ---------------------

# Policy Lambda : Aurora + VPC + Secrets
resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.env_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AuroraReadAccess"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterEndpoints"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-west-3"
          }
        }
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.terraform_remote_state.shared.outputs.db_serverless_secret_arn
      }
    ]
  })
}

# Policy EC2 : RDS + Secrets
resource "aws_iam_role_policy" "ec2_permissions" {
  name = "${var.env_prefix}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RDSReadAccess"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-west-3"
          }
        }
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.terraform_remote_state.shared.outputs.db_classique_secret_arn
      }
    ]
  })
}

# Policies AWS gérées pour les cas standards
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------
# 📊 Monitoring & Compliance Roles
# ---------------------

# CloudTrail Role - Audit et compliance
resource "aws_iam_role" "cloudtrail_role" {
  name = "${var.env_prefix}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose = "Audit and compliance logging"
    Project = "architecture-comparison"
  })
}

resource "aws_iam_role_policy" "cloudtrail_s3_access" {
  name = "${var.env_prefix}-cloudtrail-s3-policy"
  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          var.cloudtrail_bucket_arn != "" ? var.cloudtrail_bucket_arn : "*",
          var.cloudtrail_bucket_arn != "" ? "${var.cloudtrail_bucket_arn}/*" : "*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ---------------------
# 🎯 Bonnes pratiques démontrées
# ---------------------
/*
🎓 BONNES PRATIQUES DÉMONTRÉES :

1. ✅ Principe du moindre privilège
   - Permissions minimales pour Lambda, EC2, CloudTrail
   - Secrets Manager avec ARN exacts depuis remote_state

2. ✅ Séparation des responsabilités
   - Rôles distincts Lambda / EC2 / CloudTrail

3. ✅ Sécurité par défaut
   - Pas de wildcards sauf où absolument nécessaire
   - Région restreinte à eu-west-3

4. ✅ Audit et compliance
   - CloudTrail configuré avec rôle dédié et S3 access contrôlé

5. ✅ Architecture propre et évolutive
   - Modulaire, variables, outputs, tags
*/
