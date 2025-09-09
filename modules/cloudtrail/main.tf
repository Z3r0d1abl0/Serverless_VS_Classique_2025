# modules/cloudtrail/main.tf

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudTrail principal
resource "aws_cloudtrail" "main" {
  name                          = var.trail_name
  s3_bucket_name                = var.logs_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = false
  cloud_watch_logs_group_arn    = var.cloudwatch_logs_group_arn
  cloud_watch_logs_role_arn     = var.cloudwatch_logs_role_arn
  kms_key_id                    = var.kms_key_id

  # IMPORTANT : CloudTrail doit être créé APRÈS la politique S3
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]

  tags = var.tags
}

# 🔑 POLITIQUE S3 
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = var.logs_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.logs_bucket_name}"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.logs_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
          }
        }
      }
    ]
  })
}