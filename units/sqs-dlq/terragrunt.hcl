include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-sqs?ref=v4.2.0"
}

inputs = {
  name = values.name
  
  # Dead Letter Queue specific configuration
  message_retention_seconds = try(values.message_retention_seconds, 1209600) # 14 days
  visibility_timeout_seconds = try(values.visibility_timeout_seconds, 300)  # 5 minutes
  
  # Enable encryption
  kms_master_key_id = try(values.kms_master_key_id, "alias/aws/sqs")
  kms_data_key_reuse_period_seconds = try(values.kms_data_key_reuse_period_seconds, 300)
  
  # Access policy for Lambda service
  create_queue_policy = try(values.create_queue_policy, true)
  queue_policy_statements = try(values.queue_policy_statements, {})
  
  # DLQ doesn't need a DLQ itself
  create_dlq = false
  
  # Monitoring
  cloudwatch_alarm_actions = try(values.cloudwatch_alarm_actions, [])
  create_cloudwatch_alarms = try(values.create_cloudwatch_alarms, false)
  
  tags = try(values.tags, {})
}