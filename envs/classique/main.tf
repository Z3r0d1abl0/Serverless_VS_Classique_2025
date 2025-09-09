# Récupération du VPC/IGW depuis le state partagé (shared)
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket  = "my-s3-shared-backend-s-vs-c-2025"
    key     = "shared/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}

# Appel du module subnet_classique
module "subnet_classique" {
  source             = "../../modules/subnet"
  enable_nat_gateway = true
  azs                = var.azs
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  igw_id             = data.terraform_remote_state.shared.outputs.igw_id
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  env_prefix         = var.env_prefix
  tags               = var.tags
}

# Appel du module security_groups
module "security_groups" {
  source     = "../../modules/security_groups"
  vpc_id     = data.terraform_remote_state.shared.outputs.vpc_id
  vpc_cidr   = data.terraform_remote_state.shared.outputs.vpc_cidr
  env_prefix = var.env_prefix
  tags       = var.tags
}

data "aws_secretsmanager_secret" "db_classique" {
  name = data.terraform_remote_state.shared.outputs.db_classique_secret_name
}

data "aws_secretsmanager_secret_version" "db_classique" {
  secret_id = data.aws_secretsmanager_secret.db_classique.id
}

locals {
  db_creds_classique = jsondecode(data.aws_secretsmanager_secret_version.db_classique.secret_string)
}

# Appel du module RDS classique
module "rds_classique" {
  source                 = "../../modules/rds_classique"
  db_name                = var.db_name
  db_username            = local.db_creds_classique.username
  db_password            = local.db_creds_classique.password
  engine_version         = var.engine_version
  instance_class         = "db.t3.medium"
  allocated_storage      = "20"
  vpc_security_group_ids = [module.security_groups.rds_sg_id]
  subnet_ids             = module.subnet_classique.private_subnet_ids
  env_prefix             = var.env_prefix
  tags                   = var.tags
}

# Appel du module scaling_group - EC2 + Nginx
module "scaling_group" {
  source                    = "../../modules/scaling_group"
  name                      = "${var.env_prefix}-scaling-group"
  instance_type             = "t3.small"
  key_name                  = null
  security_group_ids        = [module.security_groups.sc_sg_id]
  root_volume_type          = var.root_volume_type
  root_volume_size          = var.root_volume_size
  iam_instance_profile_name = module.iam_roles.ec2_instance_profile_name
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = module.rds_classique.endpoint
    db_name     = var.db_name
    db_username = local.db_creds_classique.username
    db_password = local.db_creds_classique.password
  }))

  subnet_ids        = module.subnet_classique.public_subnet_ids
  min_size          = 2
  max_size          = 2
  desired_capacity  = 2
  target_group_arns = [module.alb.target_group_arn]
  tags              = var.tags
  depends_on        = [module.rds_classique]
}

# Appel du module ALB
module "alb" {
  source          = "../../modules/alb"
  env_prefix      = var.env_prefix
  subnet_ids      = module.subnet_classique.public_subnet_ids
  sg_id           = module.security_groups.alb_sg_id
  vpc_id          = data.terraform_remote_state.shared.outputs.vpc_id
  tags            = var.tags
  certificate_arn = data.terraform_remote_state.shared.outputs.acm_alb_arn
  web_acl_arn     = module.waf_alb.web_acl_arn
}

# Appel du module Route 53 pour le record DNS classique
data "aws_route53_zone" "main" {
  name = "projectdemocloud.com."
}

module "route_53_record_classique" {
  source                 = "../../modules/route_53"
  zone_id                = data.aws_route53_zone.main.zone_id
  name                   = "classique" # => classique.projectdemocloud.com
  type                   = "A"
  alias_name             = module.alb.alb_dns_name 
  alias_zone_id          = module.alb.zone_id      
  evaluate_target_health = true
}

# Appel du module WAF pour l'ALB
module "waf_alb" {
  source      = "../../modules/waf"
  name        = "waf-alb"
  description = "WAF for ALB in Classique"
  scope       = "REGIONAL"
  tags        = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  env_prefix              = var.env_prefix
  alb_arn_suffix          = module.alb.alb_arn_suffix
  auto_scaling_group_name = module.scaling_group.asg_name
  rds_instance_identifier = module.rds_classique.db_instance_identifier

  # Null pour serverless
  lambda_function_name       = null
  aurora_cluster_identifier  = null
  CloudFront_distribution_id = null
  tags                       = var.tags

}


# Appel du module IAM Roles (ajouté)
module "iam_roles" {
  source     = "../../modules/iam_roles"
  env_prefix = var.env_prefix
  tags       = var.tags

}