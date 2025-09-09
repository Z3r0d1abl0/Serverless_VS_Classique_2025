# =================================================================
# OUTPUTS ENVS
# =================================================================

# Outputs pour consumption par remote state dans les autres envs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR du VPC"
  value       = module.vpc.vpc_cidr
}

output "logs_bucket_name" {
  description = "Nom du bucket S3 centralisé pour les logs"
  value       = module.s3_logs_bucket.bucket_name
}

output "logs_bucket_arn" {
  description = "ARN du bucket S3 logs"
  value       = module.s3_logs_bucket.bucket_arn
}

output "igw_id" {
  value = module.vpc.igw_id
}

output "cloudtrail_arn" {
  description = "ARN du CloudTrail"
  value       = module.cloudtrail.cloudtrail_arn
}

output "db_serverless_secret_name" {
  value = module.db_secret_serverless.secret_name
}

output "db_classique_secret_name" {
  value = module.db_secret_classique.secret_name
}

output "acm_cloudfront_arn" {
  description = "ARN du certificat ACM (us-east-1) pour CloudFront"
  value       = module.acm_cloudfront.acm_certificate_arn
}

output "acm_alb_arn" {
  description = "ARN du certificat ACM (eu-west-3) pour ALB"
  value       = module.acm_alb.acm_certificate_arn
}

output "db_serverless_secret_arn" {
  description = "ARN du secret pour la DB Serverless"
  value       = module.db_secret_serverless.secret_arn
}

output "db_classique_secret_arn" {
  description = "ARN du secret pour la DB Classique"
  value       = module.db_secret_classique.secret_arn
}


# =================================================================
# 🎯 OUTPUT PRATIQUE POUR LA DEMO
# =================================================================

output "demo_links" {
  description = "Liens utiles pour la démonstration du projet"
  value = {
    cloudtrail_arn = module.cloudtrail.cloudtrail_arn
    logs_bucket    = module.s3_logs_bucket.bucket_name
  }
}