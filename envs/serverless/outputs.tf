
output "site_url" {
  description = "URL publique de mon site via CloudFront"
  value       = "https://${module.route_53_record_serverless.fqdn}/"
}

output "serverless_db_test_url" {
  description = "URL pour tester la DB serverless"
  value       = module.lambda_api_gateway.api_db_test_url
}

output "monitoring_dashboard_url" {
  description = "URL du dashboard de monitoring"
  value       = module.monitoring.dashboard_url
}

output "lambda_function_name" {
  value = module.lambda_api_gateway.lambda_function_name
}

output "aurora_cluster_identifier" {
  value = module.aurora_serverless.cluster_identifier
}

output "distribution_id" {
  value = module.cloudfront.distribution_id
}

