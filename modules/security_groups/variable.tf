variable "vpc_id" { type = string }
variable "env_prefix" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_cidr" {
  description = "CIDR du VPC (ex: 10.0.0.0/16)"
  type        = string
}

