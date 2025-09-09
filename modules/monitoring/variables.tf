# ============================================================================
# VARIABLES DE BASE
# ============================================================================
variable "env_prefix" {
  description = "Préfixe pour les noms des ressources"
  type        = string
}

variable "classic_environment" {
  description = "Nom de l'environnement classique"
  type        = string
  default     = "classique"
}

variable "serverless_environment" {
  description = "Nom de l'environnement serverless"
  type        = string
  default     = "serverless"
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VARIABLES DYNAMIQUES POUR LES RESSOURCES
# ============================================================================

# Environnement classique
variable "alb_arn_suffix" {
  description = "Suffixe ARN de l'ALB"
  type        = string
  default     = null
}

variable "auto_scaling_group_name" {
  description = "Nom du groupe Auto Scaling"
  type        = string
  default     = null
}

variable "rds_instance_identifier" {
  description = "Identifiant de l'instance RDS"
  type        = string
  default     = null
}

# Environnement serverless
variable "lambda_function_name" {
  description = "Nom de la fonction Lambda"
  type        = string
  default     = null
}

variable "aurora_cluster_identifier" {
  description = "Identifiant du cluster Aurora"
  type        = string
  default     = null
}

variable "CloudFront_distribution_id" {
  description = "ID de la distribution CloudFront"
  type        = string
  default     = null
}

variable "alb_name" {
  description = "Nom de l'ALB (pour les dashboards)"
  type        = string
  default     = null
  
}

variable "target_group_name" {
  description = "Nom du Target Group (pour les dashboards)"
  type        = string
  default     = null
}

# ============================================================================
# VARIABLES WAF
# ============================================================================
variable "waf_alb_name" {
  description = "Nom du WAF pour l'ALB"
  type        = string
  default     = null
}

variable "waf_cloudfront_name" {
  description = "Nom du WAF pour CloudFront"
  type        = string
  default     = null
}

# ============================================================================
# VARIABLES ADDITIONNELLES POUR COMPATIBILITÉ
# ============================================================================

# Aliases pour compatibilité avec l'ancien code
variable "classic_alb_name" {
  description = "Nom de l'ALB classique (utilisé dans le dashboard)"
  type        = string
  default     = null
}

variable "classic_asg_name" {
  description = "Nom du groupe Auto Scaling classique (utilisé dans le dashboard)"
  type        = string
  default     = null
}

variable "classic_rds_identifier" {
  description = "Identifiant RDS classique (utilisé dans le dashboard)"
  type        = string
  default     = null
}

variable "serverless_lambda_name" {
  description = "Nom de la Lambda serverless (utilisé dans le dashboard)"
  type        = string
  default     = null
}

variable "serverless_aurora_identifier" {
  description = "Identifiant Aurora serverless (utilisé dans le dashboard)"
  type        = string
  default     = null
}

variable "cloudfront_distribution_id" {
  description = "ID de la distribution CloudFront (corrigé)"
  type        = string
  default     = null
}