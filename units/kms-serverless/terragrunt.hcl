include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-kms?ref=v4.0.0"
}

inputs = {
  description = try(values.description, "KMS key for serverless application encryption")
  key_usage   = try(values.key_usage, "ENCRYPT_DECRYPT")

  key_administrators = try(values.key_administrators, [])
  key_users         = try(values.key_users, [])
  key_service_users = try(values.key_service_users, [])

  key_statements = try(values.key_statements, [
    {
      sid    = "Enable IAM User Permissions"
      effect = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${values.account_id}:root"]
        }
      ]
      actions   = ["kms:*"]
      resources = ["*"]
    },
    {
      sid    = "Allow Serverless Services"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["secretsmanager.amazonaws.com", "sqs.amazonaws.com", "logs.amazonaws.com"]
        }
      ]
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
    }
  ])

  aliases = try(values.aliases, [])

  # Enable key rotation for security
  enable_key_rotation = try(values.enable_key_rotation, true)

  deletion_window_in_days = try(values.deletion_window_in_days, 7)

  tags = try(values.tags, {})
}