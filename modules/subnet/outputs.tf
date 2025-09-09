output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics"
  value       = [for s in aws_subnet.public : s.id]
}

output "nat_gateway_ids" {
  description = "Liste des IDs des NAT Gateways (vide si non créées)"
  value       = var.enable_nat_gateway ? [for n in aws_nat_gateway.nat : n.id] : []
}


output "public_route_table_ids" {
  description = "Liste des IDs des route tables publiques"
  value       = [for r in aws_route_table.public : r.id]
}

output "private_route_table_ids" {
  description = "Liste des IDs des route tables privées"
  value       = [for r in aws_route_table.private : r.id]
}

