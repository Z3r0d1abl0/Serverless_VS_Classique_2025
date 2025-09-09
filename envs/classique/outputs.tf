output "url_site" {
  description = "URL publique de mon site via l'ALB"
  value       = "https://${module.route_53_record_classique.fqdn}/"
}




output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "asg_name" {
  value = module.scaling_group.asg_name
}

output "rds_endpoint" {
  value = module.rds_classique.endpoint
}

output "alb_arn_suffix" {
  value = module.alb.alb_arn_suffix
}

output "rds_instance_identifier" {
  value = module.rds_classique.db_instance_identifier
}

output "monitoring_dashboard_url" {
  value = module.monitoring.dashboard_url
}
