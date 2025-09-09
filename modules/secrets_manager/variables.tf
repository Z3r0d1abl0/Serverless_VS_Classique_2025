variable "secret_name" {
  type        = string
  description = "Nom du secret à créer dans Secrets Manager"
}
variable "description" {
  type        = string
  default     = ""
  description = "Description optionnelle du secret"
}
variable "secret_string" {
  type        = string
  sensitive   = true
  description = "Valeur du secret (JSON encodé, ex: {\"username\": \"...\", \"password\": \"...\"})"
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "env_prefix" {
  type        = string
  description = "Préfixe pour les ressources"
}