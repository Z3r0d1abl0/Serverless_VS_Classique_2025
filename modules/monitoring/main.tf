#############################################
# LOCALS – Configuration
#############################################
locals {
  has_lambda     = try(var.lambda_function_name != null && var.lambda_function_name != "", false)
  has_cloudfront = try(var.CloudFront_distribution_id != null && var.CloudFront_distribution_id != "", false)
  has_asg        = try(var.auto_scaling_group_name != null && var.auto_scaling_group_name != "", false)
  has_rds        = try(var.rds_instance_identifier != null && var.rds_instance_identifier != "", false)
  has_alb        = try(var.alb_arn_suffix != null && var.alb_arn_suffix != "", false)
  has_aurora     = try(var.aurora_cluster_identifier != null && var.aurora_cluster_identifier != "", false)
}

#############################################
# DATA SOURCE
#############################################
data "aws_region" "current" {}

#############################################
# DASHBOARD CLASSIQUE
#############################################
resource "aws_cloudwatch_dashboard" "classique" {
  count          = local.has_asg || local.has_rds || local.has_alb ? 1 : 0
  dashboard_name = "${var.env_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Dashboard Architecture - ${var.env_prefix}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          title = local.has_asg ? "Auto Scaling Group - CPU" : "ASG non configuré"
          metrics = local.has_asg ? [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.auto_scaling_group_name]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          title = local.has_alb ? "ALB - Performance" : "ALB non configuré"
          metrics = local.has_alb ? [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 24
        height = 6
        properties = {
          title = local.has_rds ? "RDS - CPU & Connections" : "RDS non configuré"
          metrics = local.has_rds ? [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_identifier]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      }
    ]
  })
}

#############################################
# DASHBOARD SERVERLESS
#############################################
resource "aws_cloudwatch_dashboard" "serverless" {
  count          = local.has_lambda || local.has_cloudfront || local.has_aurora ? 1 : 0
  dashboard_name = "${var.env_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Dashboard Architecture - ${var.env_prefix}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          title = local.has_lambda ? "Lambda - Performance" : "Lambda non configuré"
          metrics = local.has_lambda ? [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          title = local.has_cloudfront ? "CloudFront - Requests" : "CloudFront non configuré"
          metrics = local.has_cloudfront ? [
            ["AWS/CloudFront", "Requests", "DistributionId", var.CloudFront_distribution_id, "Region", "Global"]
          ] : []
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 24
        height = 6
        properties = {
          title = local.has_aurora ? "Aurora - ACU & Connections" : "Aurora non configuré"
          metrics = local.has_aurora ? [
            ["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", var.aurora_cluster_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_identifier]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          view   = "timeSeries"
        }
      }
    ]
  })
}

#############################################
# ALARME COÛT
#############################################
resource "aws_cloudwatch_metric_alarm" "cost_alert" {
  alarm_name          = "${var.env_prefix}-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 15.0
  alarm_description   = "Daily cost exceeded 15 USD"

  dimensions = {
    Currency = "USD"
  }

  tags = var.tags
}