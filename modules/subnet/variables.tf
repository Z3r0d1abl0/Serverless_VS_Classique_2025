

variable "azs" {
  description = "Liste des AZ utilisées"
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

variable "vpc_id" {
  description = "ID du VPC dans lequel les subnets seront créés"
  type        = string

}

variable "igw_id" {
  description = "ID de la Gateway Internet associée au VPC"
  type        = string

}

variable "enable_nat_gateway" {
  description = "Active ou non la création des NAT Gateway et EIP"
  type        = bool
  default     = true
}
