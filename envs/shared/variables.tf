variable "vpc_cidr" {
  description = "CIDR block pour le VPC principal"
  type        = string
}

variable "vpc_name" {
  description = "Nom du VPC"
  type        = string
}

variable "db_classique_username" {
  type      = string
  sensitive = true
}
variable "db_classique_password" {
  type      = string
  sensitive = true
}
variable "db_serverless_username" {
  type      = string
  sensitive = true
}
variable "db_serverless_password" {
  type      = string
  sensitive = true
}

variable "bucket_prefix" {
  description = "Préfixe du nom du bucket S3 logs"
  type        = string
}



variable "tags" {
  description = "Tags communs à appliquer à toutes les ressources de l'env shared"
  type        = map(string)
  default     = {}
}

variable "env_prefix" {
  description = "Préfixe pour les noms de ressources"
  type        = string
}


