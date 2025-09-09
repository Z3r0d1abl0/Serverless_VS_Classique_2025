variable "env_prefix" {
  description = "Préfixe d'environnement (ex: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC cible"
  type        = string
}

variable "private_subnet_ids" {
  description = "Liste des subnets privés pour la Lambda"
  type        = list(string)
}

variable "lambda_zip_path" {
  description = "Chemin vers l’archive zip du code Lambda"
  type        = string
}

variable "tags" {
  description = "Tags optionnels AWS"
  type        = map(string)
  default     = {}
}

variable "lambda_sg_id" {
  description = "ID du Security Group à attacher à la Lambda"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN du rôle IAM à attacher à la Lambda"
  type        = string
}



# Variables pour la connexion Aurora
variable "aurora_endpoint" {
  description = "Aurora cluster endpoint"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "testdb"
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "3306"
}