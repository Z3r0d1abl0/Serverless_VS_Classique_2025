variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "region" {
  description = "Région AWS"
  type        = string
}

variable "env_prefix" {
  description = "Préfixe de l'environnement (ex: serverless)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Liste des subnets privés"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Liste des route tables privées"
  type        = list(string)
}



variable "vpce_sg_id" {
  description = "ID du Security Group pour les VPC Endpoints"
  type        = string
}


variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}
