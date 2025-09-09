# envs/classique/variables.tf

variable "azs" {
  description = "Liste des zones de disponibilité"
  type        = list(string)

}

variable "public_subnets" {
  description = "Map des subnets publics : clé => {cidr, az}"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Map des subnets privés : clé => {cidr, az}"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "db_name" { type = string }
variable "engine_version" { type = string }

variable "root_volume_size" {
  description = "Taille du volume racine (en Go)"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Type de volume racine (gp2, io1, etc.)"
  type        = string
  default     = "gp2"
}

variable "env_prefix" {
  description = "Préfixe des ressources"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}
