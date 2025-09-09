# ============================================================================
# OUTPUTS DU MODULE MONITORING
# ============================================================================

output "dashboard_name" {
  description = "Nom du dashboard CloudWatch"
  value = (
    local.has_asg || local.has_rds ? aws_cloudwatch_dashboard.classique[0].dashboard_name :
    local.has_lambda || local.has_cloudfront ? aws_cloudwatch_dashboard.serverless[0].dashboard_name :
    null
  )
}

output "dashboard_url" {
  description = "URL du dashboard CloudWatch"
  value = (
    local.has_asg || local.has_rds ?
    "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.classique[0].dashboard_name}" :
    local.has_lambda || local.has_cloudfront ?
    "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.serverless[0].dashboard_name}" :
    null
  )
}




# ============================================================================
# OUTPUTS DES ALARMES CLASSIQUES
# ============================================================================
output "classic_alarms" {
  value = {
    asg_capacity = var.auto_scaling_group_name != null && var.auto_scaling_group_name != "" ? "${var.env_prefix}-classic-asg-capacity" : null
  }
}

# ============================================================================
# OUTPUTS DES ALARMES SERVERLESS
# ============================================================================
output "serverless_alarms" {
  description = "Liste des alarmes pour l'architecture serverless"
  value = {
    lambda_errors      = var.lambda_function_name != null && var.lambda_function_name != "" ? "${var.env_prefix}-lambda-errors" : null
    aurora_connections = var.aurora_cluster_identifier != null && var.aurora_cluster_identifier != "" ? "${var.env_prefix}-aurora-connections" : null
  }
}

# ============================================================================
# OUTPUTS POUR LE PORTFOLIO
# ============================================================================
output "monitoring_summary" {
  description = "Résumé des ressources de monitoring créées"
  value = {
    dashboard = {
      name = (
        local.has_asg || local.has_rds ?
        aws_cloudwatch_dashboard.classique[0].dashboard_name :
        local.has_lambda || local.has_cloudfront ?
        aws_cloudwatch_dashboard.serverless[0].dashboard_name :
        null
      )
      url = (
        local.has_asg || local.has_rds ?
        "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.classique[0].dashboard_name}" :
        local.has_lambda || local.has_cloudfront ?
        "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.serverless[0].dashboard_name}" :
        null
      )
    }

    

    architectures_monitored = {
      classic    = var.auto_scaling_group_name != null && var.auto_scaling_group_name != ""
      serverless = var.lambda_function_name != null && var.lambda_function_name != ""
    }
  }
}
