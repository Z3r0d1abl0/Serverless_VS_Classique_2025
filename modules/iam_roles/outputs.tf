# Outputs pour Lambda
output "lambda_role_arn" {
  description = "ARN du rôle Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Nom du rôle Lambda"
  value       = aws_iam_role.lambda_role.name
}

# Outputs pour EC2
output "ec2_role_arn" {
  description = "ARN du rôle EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Nom du profil d'instance EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# Outputs pour CloudTrail
output "cloudtrail_role_arn" {
  description = "ARN du rôle CloudTrail"
  value       = aws_iam_role.cloudtrail_role.arn
}

