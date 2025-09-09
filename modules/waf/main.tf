terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = var.description
  scope       = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  # Règle existante - Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Exclusions conditionnelles pour éviter les faux positifs
        dynamic "rule_action_override" {
          for_each = var.common_rule_exclusions
          content {
            action_to_use {
              count {}
            }
            name = rule_action_override.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # RÈGLE 2 - Protection contre les entrées malveillantes connues
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # RÈGLE 3 - Protection contre les bots malveillants (conditionnelle)
  dynamic "rule" {
    for_each = var.enable_bot_protection ? [1] : []
    content {
      name     = "AWS-AWSManagedRulesBotControlRuleSet"
      priority = 3

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BotControl"
        sampled_requests_enabled   = true
      }
    }
  }

  # RÈGLE 4 - Blocage géographique conditionnel
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      name     = "GeoBlocking"
      priority = 4

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoBlocking"
        sampled_requests_enabled   = true
      }
    }
  }

  # RÈGLE 5 - Blocage User-Agents suspects
  dynamic "rule" {
    for_each = length(var.blocked_user_agents) > 0 ? [1] : []
    content {
      name     = "BlockSuspiciousUserAgents"
      priority = 5

      action {
        block {}
      }

      statement {
        or_statement {
          dynamic "statement" {
            for_each = var.blocked_user_agents
            content {
              byte_match_statement {
                search_string = statement.value
                field_to_match {
                  single_header {
                    name = "user-agent"
                  }
                }
                text_transformation {
                  priority = 1
                  type     = "LOWERCASE"
                }
                positional_constraint = "CONTAINS"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BlockedUserAgents"
        sampled_requests_enabled   = true
      }
    }
  }

  # RÈGLE 6 - Protection contre les requêtes avec des tailles suspectes
  dynamic "rule" {
    for_each = var.enable_size_restrictions ? [1] : []
    content {
      name     = "SizeRestrictions"
      priority = 6

      action {
        block {}
      }

      statement {
        or_statement {
          # Bloquer les requêtes avec des headers trop longs
          statement {
            size_constraint_statement {
              field_to_match {
                all_query_arguments {}
              }
              comparison_operator = "GT"
              size                = var.max_query_string_length
              text_transformation {
                priority = 1
                type     = "NONE"
              }
            }
          }
          # Bloquer les requêtes avec des URIs trop longues
          statement {
            size_constraint_statement {
              field_to_match {
                uri_path {}
              }
              comparison_operator = "GT"
              size                = var.max_uri_length
              text_transformation {
                priority = 1
                type     = "NONE"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "SizeRestrictions"
        sampled_requests_enabled   = true
      }
    }
  }

  # RÈGLE 7 - Rate Limiting
  rule {
    name     = "LimitRequests1000Per5Minutes"
    priority = 7

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
}