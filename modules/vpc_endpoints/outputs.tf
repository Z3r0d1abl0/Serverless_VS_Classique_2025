output "vpc_endpoint_ids" {
  description = "Liste des IDs des VPC Endpoints"
  value = [
    aws_vpc_endpoint.s3.id,
    aws_vpc_endpoint.secretsmanager.id,
    aws_vpc_endpoint.kms.id,
    aws_vpc_endpoint.cloudwatch_logs.id
  ]
}

output "vpc_endpoint_dns_names" {
  description = "DNS names des VPC Endpoints (Interface uniquement)"
  value = [
    aws_vpc_endpoint.secretsmanager.dns_entry[*].dns_name,
    aws_vpc_endpoint.kms.dns_entry[*].dns_name,
    aws_vpc_endpoint.cloudwatch_logs.dns_entry[*].dns_name
  ]
}
