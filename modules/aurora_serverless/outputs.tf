output "cluster_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "cluster_arn" {
  value = aws_rds_cluster.aurora.arn
}

output "cluster_identifier" {
  value = aws_rds_cluster.aurora.id
}
