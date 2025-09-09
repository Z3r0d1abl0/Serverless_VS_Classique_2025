output "acm_certificate_arn" {
  description = "ARN du certificat ACM"
  value       = aws_acm_certificate.this.arn
}
