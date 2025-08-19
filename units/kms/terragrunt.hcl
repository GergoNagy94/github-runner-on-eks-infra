include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-kms?ref=v4.0.0"
}

inputs = {
  description = try(values.description, "KMS key for EKS cluster encryption")
  key_usage   = try(values.key_usage, "ENCRYPT_DECRYPT")

  key_administrators = try(values.key_administrators, [])
  key_users         = try(values.key_users, [])
  key_service_users = try(values.key_service_users, [])

  key_statements = try(values.key_statements, [
    {
      sid    = "Allow EKS Service"
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["eks.amazonaws.com"]
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

  deletion_window_in_days = try(values.deletion_window_in_days, 7)

  tags = try(values.tags, {})
}