variable "env_prefix" {
  description = "Préfixe d'environnement pour le nommage"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "sg_id" {
  description = "ID du security group pour l'ALB"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des subnets publics"
  type        = list(string)
}

variable "instance_id" {
  description = "ID de l’instance EC2 à attacher"
  type        = string
  default     = null
}

variable "attach_instance" {
  description = "Attacher l’instance EC2 automatiquement (true/false)"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ARN du certificat ACM pour HTTPS"
  type        = string
}

variable "web_acl_arn" {
  description = "ARN du WAF à attacher à l'ALB"
  type        = string
  default     = null
}


variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}
