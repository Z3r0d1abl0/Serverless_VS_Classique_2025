variable "trail_name" {
  description = "Nom du trail CloudTrail"
  type        = string
}

variable "logs_bucket_name" {
  description = "Nom du bucket S3 où envoyer les logs CloudTrail"
  type        = string
}

variable "cloudwatch_logs_group_arn" {
  description = "ARN du log group CloudWatch pour CloudTrail"
  type        = string
  default     = null
}

variable "cloudwatch_logs_role_arn" {
  description = "ARN du rôle IAM pour exporter vers CloudWatch Logs"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "Clé KMS à utiliser pour le chiffrement des logs (optionnel)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags à appliquer"
  type        = map(string)
  default     = {}
}
