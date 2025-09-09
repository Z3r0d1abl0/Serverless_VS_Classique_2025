variable "log_group_name" {
  description = "Nom du CloudWatch Log Group"
  type        = string
}

variable "retention_in_days" {
  description = "Durée de rétention des logs (en jours)"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags à appliquer"
  type        = map(string)
  default     = {}
}
