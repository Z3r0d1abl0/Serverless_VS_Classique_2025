# envs/serverless/variables.tf

variable "azs" {
  description = "Liste des zones de disponibilité"
  type        = list(string)

}

variable "public_subnets" {
  description = "Map des subnets publics : clé => {cidr, az}"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Map des subnets privés : clé => {cidr, az}"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "env_prefix" {
  description = "Préfixe pour les ressources"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

# Variables for Aurora Serverless Module
variable "db_name" { type = string }
variable "engine_version" { type = string }

variable "lambda_zip_path" {
  description = "Chemin vers l’archive zip contenant le code Lambda"
  type        = string
}



