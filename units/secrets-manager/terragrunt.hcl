include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-secrets-manager?ref=v1.3.1"
}

inputs = {
  name        = values.name
  description = try(values.description, "Database credentials and application secrets")

  secret_string = try(values.secret_string, jsonencode({
    username = values.db_username
    password = values.db_password
  }))

  enable_rotation     = try(values.enable_rotation, false)
  rotation_lambda_arn = try(values.rotation_lambda_arn, null)
  rotation_rules = try(values.enable_rotation, false) ? try(values.rotation_rules, {
    automatically_after_days = 30
  }) : {}

  create_replica = try(values.create_replica, false)
  replica        = try(values.create_replica, false) ? try(values.replica, {}) : {}

  recovery_window_in_days = try(values.recovery_window_in_days, 7)
  ignore_secret_changes   = try(values.ignore_secret_changes, false)

  create_policy     = try(values.create_policy, false)
  policy_statements = try(values.policy_statements, {})

  block_public_policy = try(values.block_public_policy, true)

  tags = try(values.tags, {})
}