variable "env_prefix" {
  description = "Préfixe pour les noms des ressources"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}

# Variables pour CloudTrail
variable "cloudtrail_bucket_arn" {
  description = "ARN du bucket S3 pour CloudTrail"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour CloudTrail"
  type        = string
  default     = ""
}

# Variables pour monitoring
variable "sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes"
  type        = string
  default     = ""
}

# Variables pour Terraform backend
variable "backend_kms_key_arn" {
  description = "ARN de la clé KMS pour le backend Terraform"
  type        = string
  default     = ""
}