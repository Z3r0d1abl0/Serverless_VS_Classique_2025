output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.main.id
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

output "vpc_cidr" {
  description = "CIDR du VPC"
  value       = aws_vpc.main.cidr_block
}
