output "lambda_function_name" {
  description = "Nom de la fonction Lambda"
  value       = aws_lambda_function.main.function_name
}

output "api_gw_url" {
  description = "URL publique de l’API Gateway"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "api_db_test_url" {
  description = "URL complète pour tester la DB via API Gateway"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/api/db-test"
}