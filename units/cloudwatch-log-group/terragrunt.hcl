include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-cloudwatch//modules/log-group?ref=v5.3.1"
}

inputs = {
  name = values.name
  
  # Log retention configuration
  retention_in_days = try(values.retention_in_days, 14)
  
  # Encryption configuration
  kms_key_id = try(values.kms_key_id, null)
  
  # Log group policy
  create_log_group_policy = try(values.create_log_group_policy, false)
  log_group_policy = try(values.log_group_policy, null)
  
  # Skip destroy for production log groups
  skip_destroy = try(values.skip_destroy, false)
  
  tags = try(values.tags, {})
}