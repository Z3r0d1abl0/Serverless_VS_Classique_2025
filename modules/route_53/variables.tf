variable "zone_id" {
  description = "ID de la zone Route 53"
  type        = string
}
variable "name" {
  description = "Nom du record DNS (ex: www, api, root '')"
  type        = string
}
variable "type" {
  description = "Type du record (A le plus courant pour ALIAS AWS)"
  type        = string
  default     = "A"
}
variable "alias_name" {
  description = "Nom DNS cible pour ALIAS (CloudFront, ALB, etc.)"
  type        = string
}
variable "alias_zone_id" {
  description = "Zone ID de la cible (CloudFront, ALB, etc.)"
  type        = string
}
variable "evaluate_target_health" {
  description = "Active le health check Route 53 sur la cible"
  type        = bool
  default     = false
}
