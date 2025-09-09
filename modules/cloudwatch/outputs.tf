output "log_group_name" {
  description = "Nom du log group CloudWatch"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "log_group_arn" {
  description = "ARN du log group CloudWatch"
  value       = aws_cloudwatch_log_group.lambda_log_group.arn
}
