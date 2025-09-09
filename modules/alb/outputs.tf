output "alb_dns_name" {
  description = "Nom DNS de l’ALB"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN du Target Group"
  value       = aws_lb_target_group.this.arn
}

output "alb_arn" {
  description = "ARN de l’ALB"
  value       = aws_lb.this.arn
}

# Métriques CloudWatch
output "alb_arn_suffix" {
  description = "Suffixe ARN de l'ALB pour CloudWatch"
  value       = aws_lb.this.arn_suffix
}

output "zone_id" {
  description = "Zone ID de l’ALB pour les enregistrements DNS"
  value       = aws_lb.this.zone_id
}

