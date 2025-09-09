variable "name" {
  description = "Nom du scaling group"
  type        = string
}


variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
}

variable "key_name" {
  description = "Nom de la key pair pour SSH"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Liste des SG à attacher"
  type        = list(string)
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Liste des subnets (multi-AZ!)"
  type        = list(string)
}

variable "min_size" {
  description = "Min d'instances"
  type        = number
}

variable "max_size" {
  description = "Max d'instances"
  type        = number
}

variable "desired_capacity" {
  description = "Nb désiré d'instances"
  type        = number
}

variable "root_volume_size" {
  description = "Taille du volume racine (en Go)"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Type de volume racine (gp2, io1, etc.)"
  type        = string
  default     = "gp2"
}

variable "target_group_arns" {
  description = "Liste des ARNs de target groups (pour ALB)"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "Nom du profil d'instance IAM pour EC2"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags à appliquer"
  type        = map(string)
  default     = {}
}
