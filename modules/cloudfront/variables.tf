variable "aliases" {
  description = "Liste des noms de domaine (CNAMEs) à associer à la distribution"
  type        = list(string)
  default     = []
}

variable "s3_domain_name" {
  description = "Nom de domaine du bucket S3 (static website hosting)"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "Nom de domaine d'API Gateway (invoke URL ou custom domain)"
  type        = string
  default     = ""
}

variable "api_gateway_path" {
  description = "Chemin d'API Gateway (souvent vide, sauf API en sous-répertoire)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN du certificat ACM (doit être dans us-east-1 pour CloudFront)"
  type        = string
}

variable "web_acl_id" {
  description = "ARN du WAF à attacher à la distribution (optionnel)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Classe de prix CloudFront (par défaut, PriceClass_100 = Europe + US seulement)"
  type        = string
  default     = "PriceClass_100"
}


variable "cloudfront_oai_path" {
  description = "CloudFront Origin Access Identity path"
  type        = string
}
variable "tags" {
  description = "Tags à associer à la distribution"
  type        = map(string)
  default     = {}
}
