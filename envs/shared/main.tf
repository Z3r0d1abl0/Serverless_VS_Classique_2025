# Appel du module VPC (créé dans modules/vpc)
module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  tags     = var.tags
}

# Appel du module S3 pour les logs (créé dans modules/s3_logs_bucket)
module "s3_logs_bucket" {
  source        = "../../modules/s3_logs_bucket"
  bucket_prefix = var.bucket_prefix
  tags          = var.tags
}
# Appel du module cloudtrail (créé dans modules/cloudtrail)
module "cloudtrail" {
  source           = "../../modules/cloudtrail"
  trail_name       = "projet-s-vs-c-2025-cloudtrail"
  logs_bucket_name = module.s3_logs_bucket.bucket_name
  kms_key_id       = module.s3_logs_bucket.kms_key_arn
  tags             = var.tags
  # cloudwatch_logs_group_arn, cloudwatch_logs_role_arn, kms_key_id restent à null (pas besoin de les passer)
}
# Appel du mode secrets_manager pour les identifiants de la base de données (classique et serverless )
module "db_secret_classique" {
  source      = "../../modules/secrets_manager"
  env_prefix  = var.env_prefix
  secret_name = "db-secret-classique"
  description = "Identifiants DB pour l'architecture classique"
  secret_string = jsonencode({
    username = var.db_classique_username
    password = var.db_classique_password
  })
  tags = {
    env     = "classique"
    project = "S_Vs_C_2025"
  }
}

module "db_secret_serverless" {
  source      = "../../modules/secrets_manager"
  env_prefix  = var.env_prefix
  secret_name = "db-secret-serverless"
  description = "Identifiants DB pour l'architecture serverless"
  secret_string = jsonencode({
    username = var.db_serverless_username
    password = var.db_serverless_password
  })
  tags = {
    env     = "serverless"
    project = "S_Vs_C_2025"
  }
}


# Appel du module ACM pour le certificat SSL

# Zone Route 53 (déjà créée normalement)
data "aws_route53_zone" "main" {
  name = "projectdemocloud.com."
}

# Certificat ACM pour CloudFront (us-east-1)
module "acm_cloudfront" {
  source          = "../../modules/acm"
  domain_name     = "serverless.projectdemocloud.com"
  san             = []
  route53_zone_id = data.aws_route53_zone.main.zone_id
  providers = {
    aws = aws.useast1
  }
}

# Certificat ACM pour ALB (eu-west-3)
module "acm_alb" {
  source          = "../../modules/acm"
  domain_name     = "classique.projectdemocloud.com"
  san             = []
  route53_zone_id = data.aws_route53_zone.main.zone_id
  # Pas besoin d'alias provider, utilise eu-west-3 par défaut
}
