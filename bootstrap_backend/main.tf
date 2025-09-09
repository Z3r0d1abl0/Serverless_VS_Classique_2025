# ---------------------
# Identité & auto-détection du principal Terraform
# ---------------------
data "aws_caller_identity" "current" {}

locals {
  terraform_principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Z3r0d1ablo"
}

# ---------------------
# KMS CMK pour chiffrer le bucket de state
# ---------------------
resource "aws_kms_key" "tfstate" {
  description             = "CMK for Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAdmin"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowTerraformPrincipalUseOfKey"
        Effect = "Allow"
        Principal = {
          AWS = local.terraform_principal_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/tfstate-backend-v2"
  target_key_id = aws_kms_key.tfstate.key_id
}

# ---------------------
# S3 bucket backend
# ---------------------
resource "aws_s3_bucket" "tfstate" {
  bucket        = "my-s3-shared-backend-s-vs-c-2025" # doit être globalement unique
  force_destroy = true

  tags = {
    Name        = "my-s3-shared-backend-s-vs-c-2025"
    Environment = "Bootstrap"
  }
}

# Versioning activé
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

# Chiffrement SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
    bucket_key_enabled = true
  }
}

# Bloquer l'accès public
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------
# Policy TLS obligatoire
# ---------------------
data "aws_iam_policy_document" "tfstate_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate_bucket.json
}

# ---------------------
# Table DynamoDB pour le lock Terraform
# ---------------------
resource "aws_dynamodb_table" "state_lock" {
  name         = "tfstate-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery { enabled = true }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "Bootstrap"
  }
}

