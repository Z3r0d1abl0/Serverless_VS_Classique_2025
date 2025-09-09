variable "domain_name" {
  description = "Nom de domaine principal pour le certificat ACM"
  type        = string
}

variable "san" {
  description = "Liste des Subject Alternative Names"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "ID de la zone Route 53"
  type        = string
}
