
output "distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "Nom de domaine de la distribution CloudFront"
  value       = aws_cloudfront_distribution.this.domain_name
}
