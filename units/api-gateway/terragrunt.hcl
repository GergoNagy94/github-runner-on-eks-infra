include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-apigateway-v2?ref=v5.3.0"
}

dependency "lambda" {
  config_path = values.lambda_path
  mock_outputs = {
    lambda_function_arn         = "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    lambda_function_name        = "mock-function"
    lambda_function_invoke_arn  = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:mock-function/invocations"
  }
}

inputs = {
  name          = values.name
  description   = try(values.description, "HTTP API for serverless application")
  protocol_type = try(values.protocol_type, "HTTP")

  cors_configuration = try(values.cors_configuration, {
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
    allow_credentials = false
  })

  domain_name                 = try(values.domain_name, "")
  domain_name_certificate_arn = try(values.domain_name_certificate_arn, null)

  default_stage_access_log_destination_arn = try(values.access_log_destination_arn, null)
  default_stage_access_log_format = try(values.access_log_format, jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
  }))

  default_route_settings = try(values.default_route_settings, {
    detailed_metrics_enabled = false
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  })

  integrations = {
    "POST /" = {
      lambda_arn               = dependency.lambda.outputs.lambda_function_arn
      payload_format_version   = "2.0"
      timeout_milliseconds     = 12000
      integration_type         = "AWS_PROXY"
      integration_method       = "POST"
      create_lambda_permission = true
    }

    "GET /" = {
      lambda_arn               = dependency.lambda.outputs.lambda_function_arn
      payload_format_version   = "2.0"
      timeout_milliseconds     = 12000
      integration_type         = "AWS_PROXY"
      integration_method       = "POST"
      create_lambda_permission = true
    }

    "GET /health" = {
      lambda_arn               = dependency.lambda.outputs.lambda_function_arn
      payload_format_version   = "2.0"
      timeout_milliseconds     = 12000
      integration_type         = "AWS_PROXY"
      integration_method       = "POST"
      create_lambda_permission = true
    }

    "$default" = {
      lambda_arn               = dependency.lambda.outputs.lambda_function_arn
      payload_format_version   = "2.0"
      timeout_milliseconds     = 12000
      integration_type         = "AWS_PROXY"
      integration_method       = "POST"
      create_lambda_permission = true
    }
  }

  create_domain_name = try(values.create_domain_name, false)
  
  tags = try(values.tags, {})
}

