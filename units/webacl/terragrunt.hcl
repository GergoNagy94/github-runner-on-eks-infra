include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:umotif-public/terraform-aws-waf-webaclv2?ref=5.1.2"
}

inputs = {
  name        = values.name
  name_prefix = try(values.name_prefix, values.name)
  scope       = try(values.scope, "CLOUDFRONT") # CLOUDFRONT for global, REGIONAL for ALB/API Gateway

  default_action = try(values.default_action, "allow")

  rules = try(values.rules, [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSetMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 2

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
        sampled_requests_enabled   = true
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
  ])

  rate_based_rules = try(values.rate_based_rules, [
    {
      name     = "RateLimitRule"
      priority = 100
      action   = "block"
      limit    = 2000

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitRule"
        sampled_requests_enabled   = true
      }
    }
  ])

  ip_sets_rule = try(values.ip_sets_rule, [])

  geo_allowlist_rule = try(values.geo_allowlist_rule, [])
  geo_blocklist_rule = try(values.geo_blocklist_rule, [])

  visibility_config = try(values.visibility_config, {
    cloudwatch_metrics_enabled = true
    metric_name                = "${values.name}Metric"
    sampled_requests_enabled   = true
  })

  create_logging_configuration = try(values.create_logging_configuration, false)
  log_destination_configs      = try(values.log_destination_configs, [])
  redacted_fields = try(values.redacted_fields, [
    {
      single_header = {
        name = "authorization"
      }
    }
  ])

  tags = try(values.tags, {})
}