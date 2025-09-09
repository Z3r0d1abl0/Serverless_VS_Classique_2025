output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "lt_id" {
  description = "ID du Launch Template"
  value       = aws_launch_template.this.id
}
output "asg_id" {
  description = "ID de l'Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}