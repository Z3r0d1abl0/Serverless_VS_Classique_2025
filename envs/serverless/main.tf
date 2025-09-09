data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket  = "my-s3-shared-backend-s-vs-c-2025"
    key     = "shared/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}

module "security_groups" {
  source     = "../../modules/security_groups"
  vpc_id     = data.terraform_remote_state.shared.outputs.vpc_id
  vpc_cidr   = data.terraform_remote_state.shared.outputs.vpc_cidr
  env_prefix = var.env_prefix
  tags       = var.tags
}

module "subnet" {
  source             = "../../modules/subnet"
  enable_nat_gateway = false
  azs                = var.azs
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  igw_id             = data.terraform_remote_state.shared.outputs.igw_id
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  env_prefix         = var.env_prefix
  tags               = var.tags
}

data "aws_secretsmanager_secret" "db_serverless" {
  name = data.terraform_remote_state.shared.outputs.db_serverless_secret_name
}

data "aws_secretsmanager_secret_version" "db_serverless" {
  secret_id = data.aws_secretsmanager_secret.db_serverless.id
}

locals {
  db_creds_serverless = jsondecode(data.aws_secretsmanager_secret_version.db_serverless.secret_string)
}


# Aurora Serverless Configuration
module "aurora_serverless" {
  source             = "../../modules/aurora_serverless"
  db_name            = var.db_name
  db_username        = local.db_creds_serverless.username
  db_password        = local.db_creds_serverless.password
  engine_version     = var.engine_version
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  subnet_ids         = module.subnet.private_subnet_ids
  security_group_ids = [module.security_groups.aurora_sg_id]
  env_prefix         = var.env_prefix
  tags               = var.tags
}


# Lambda Function and API Gateway Configuration
module "lambda_api_gateway" {
  source             = "../../modules/lambda_api_gateway"
  env_prefix         = var.env_prefix
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  private_subnet_ids = module.subnet.private_subnet_ids
  lambda_zip_path    = var.lambda_zip_path
  tags               = var.tags

  lambda_sg_id    = module.security_groups.lambda_sg_id
  lambda_role_arn = module.iam_roles.lambda_role_arn # Utilisation du rôle IAM créé dans le module iam_roles
  aurora_endpoint = module.aurora_serverless.cluster_endpoint
  db_username     = local.db_creds_serverless.username
  db_password     = local.db_creds_serverless.password
  db_name         = var.db_name
  db_port         = "3306"

}

# WAF Configuration for CloudFront
module "waf_cloudfront" {
  source = "../../modules/waf"
  providers = {
    aws = aws.useast1
  }
  name        = "waf-cloudfront"
  description = "WAF for CloudFront in Serverless"
  scope       = "CLOUDFRONT"
  tags        = var.tags
}

#CloudFront Origin Access Identity (OAI) créé séparément
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for S3 website bucket"
}

# S3 website module (utilise l'OAI créé ci-dessus)
resource "random_pet" "s3_bucket_suffix" {
  length    = 2
  separator = "-"
}

locals {
  website_bucket_name = "web-serverless-erwan-${random_pet.s3_bucket_suffix.id}"
}

module "s3_website" {
  source             = "../../modules/s3_website"
  bucket_name        = local.website_bucket_name
  cloudfront_oai_arn = aws_cloudfront_origin_access_identity.main.iam_arn
  classique_url      = "https://classique.projectdemocloud.com" # URL de votre env classique
  serverless_api_url = module.lambda_api_gateway.api_db_test_url
  alb_name           = "ALB-Classique"
  lambda_name        = module.lambda_api_gateway.lambda_function_name
  aurora_cluster     = module.aurora_serverless.cluster_identifier
  tags               = var.tags
  depends_on = [ aws_cloudfront_origin_access_identity.main ]
}

# CloudFront module (utilise l'OAI externe)
module "cloudfront" {
  source                  = "../../modules/cloudfront"
  aliases                 = ["serverless.projectdemocloud.com"]
  s3_domain_name          = module.s3_website.bucket_regional_domain_name
  cloudfront_oai_path     = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
  api_gateway_domain_name = replace(module.lambda_api_gateway.api_gw_url, "https://", "")
  api_gateway_path        = "/prod"
  acm_certificate_arn     = data.terraform_remote_state.shared.outputs.acm_cloudfront_arn
  web_acl_id              = module.waf_cloudfront.web_acl_arn
  price_class             = "PriceClass_100"
  tags                    = var.tags

  depends_on = [module.waf_cloudfront, module.s3_website]
}


# Route 53 DNS Record for Serverless
data "aws_route53_zone" "main" {
  name = "projectdemocloud.com."
}

module "route_53_record_serverless" {
  source                 = "../../modules/route_53"
  zone_id                = data.aws_route53_zone.main.zone_id
  name                   = "serverless" # => serverless.projectdemocloud.com
  type                   = "A"
  alias_name             = module.cloudfront.cloudfront_domain_name
  alias_zone_id          = "Z2FDTNDATAQYW2" # CloudFront zone ID (fixe)
  evaluate_target_health = false
}

# VPC Endpoints pour serverless
module "vpc_endpoints" {
  source                  = "../../modules/vpc_endpoints"
  vpc_id                  = data.terraform_remote_state.shared.outputs.vpc_id
  region                  = "eu-west-3"
  env_prefix              = var.env_prefix
  private_subnet_ids      = module.subnet.private_subnet_ids
  private_route_table_ids = module.subnet.private_route_table_ids
  vpce_sg_id              = module.security_groups.vpce_sg_id
  tags                    = var.tags
}

# Appel du module IAM Roles (ajouté)
module "iam_roles" {
  source     = "../../modules/iam_roles"
  env_prefix = var.env_prefix
  tags       = var.tags

}

# Appel du module Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  env_prefix              = var.env_prefix
  alb_arn_suffix          = null
  auto_scaling_group_name = null
  rds_instance_identifier = null

  lambda_function_name       = module.lambda_api_gateway.lambda_function_name
  aurora_cluster_identifier  = module.aurora_serverless.cluster_identifier
  CloudFront_distribution_id = module.cloudfront.distribution_id
  tags                       = var.tags
}
