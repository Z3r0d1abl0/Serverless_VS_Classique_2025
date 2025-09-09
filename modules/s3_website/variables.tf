variable "bucket_name" {
  description = "Le nom du bucket S3 pour l’hébergement du site statique"
  type        = string
}


variable "cloudfront_oai_arn" {
  description = "CloudFront Origin Access Identity ARN"
  type        = string
  default     = null
}




variable "api_gateway_path" {
  description = "API Gateway stage path"
  type        = string
  default     = "/prod"
}

variable "classique_url" {
  description = "URL de l'architecture classique pour les tests"
  type        = string
}

variable "serverless_api_url" {
  description = "URL de l'API Gateway pour les tests DB"
  type        = string
}

variable "alb_name" {
  description = "Nom du Load Balancer (pour affichage)"
  type        = string
}

variable "lambda_name" {
  description = "Nom de la fonction Lambda"
  type        = string
}

variable "aurora_cluster" {
  description = "Nom du cluster Aurora"
  type        = string
}


variable "tags" {
  description = "Tags à appliquer au bucket"
  type        = map(string)
  default     = {}
}
