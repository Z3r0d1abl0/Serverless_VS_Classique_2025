output "fqdn" {
  description = "Nom DNS complet créé"
  value       = aws_route53_record.this.fqdn
}
