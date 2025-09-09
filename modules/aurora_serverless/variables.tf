variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "engine_version" { type = string } 
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "env_prefix" { type = string }
variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "min_capacity" {
  type        = number
  default     = 0.5   # Réduit pour tests (0.5 ACU minimum pour V2)
  description = "Capacité minimum en ACU pour Aurora Serverless V2 (0.5 minimum)"
}

variable "max_capacity" {
  type        = number
  default     = 4.0  # Réduit pour éviter les coûts élevés
  description = "Capacité maximum en ACU pour Aurora Serverless V2"
}
