
variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "engine_version" {
  type = string
}
variable "env_prefix" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
