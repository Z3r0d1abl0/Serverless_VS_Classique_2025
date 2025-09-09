variable "bucket_prefix" {
  description = "Préfixe du nom du bucket S3 logs (en minuscules, sans espaces ni caractères spéciaux)"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer"
  type        = map(string)
  default     = {}
}
