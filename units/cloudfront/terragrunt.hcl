include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-cloudfront?ref=v5.0.0"
}

dependency "acm" {
  config_path  = values.acm_path
  skip_outputs = try(values.use_custom_certificate, false) ? false : true
  mock_outputs = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
}

dependency "s3" {
  config_path = values.s3_path
  mock_outputs = {
    s3_bucket_bucket_domain_name = "mock-bucket.s3.amazonaws.com"
    s3_bucket_id                 = "mock-bucket"
    s3_bucket_arn                = "arn:aws:s3:::mock-bucket"
  }
}

dependency "webacl" {
  config_path  = values.webacl_path
  skip_outputs = try(values.enable_waf, false) ? false : true
  mock_outputs = {
    arn = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/mock/12345678-1234-1234-1234-123456789012"
  }
}

inputs = {
  aliases = try(values.aliases, [])

  comment         = try(values.comment, "CloudFront distribution for ${dependency.s3.outputs.s3_bucket_id}")
  enabled         = try(values.enabled, true)
  is_ipv6_enabled = try(values.is_ipv6_enabled, true)
  price_class     = try(values.price_class, "PriceClass_All")

  origin = {
    s3_bucket = {
      domain_name            = dependency.s3.outputs.s3_bucket_bucket_domain_name
      origin_access_control = "s3_bucket"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_bucket"
    viewer_protocol_policy = try(values.viewer_protocol_policy, "redirect-to-https")

    allowed_methods = try(values.allowed_methods, ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods  = try(values.cached_methods, ["GET", "HEAD"])
    compress        = try(values.compress, true)
    query_string    = try(values.query_string, false)
    cookies_forward = try(values.cookies_forward, "none")
    headers         = try(values.headers, [])

    min_ttl     = try(values.min_ttl, 0)
    default_ttl = try(values.default_ttl, 3600)
    max_ttl     = try(values.max_ttl, 86400)
  }

  ordered_cache_behavior = try(values.ordered_cache_behavior, [])

  custom_error_response = try(values.custom_error_response, [])

  create_origin_access_control = true
  origin_access_control = {
    s3_bucket = {
      description      = "S3 bucket OAC for ${dependency.s3.outputs.s3_bucket_id}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  viewer_certificate = try(values.use_custom_certificate, false) ? {
    acm_certificate_arn = dependency.acm.outputs.acm_certificate_arn
    ssl_support_method  = "sni-only"
    } : try(values.viewer_certificate, {
      cloudfront_default_certificate = true
  })

  geo_restriction = try(values.geo_restriction, {
    restriction_type = "none"
  })

  web_acl_id = try(values.enable_waf, false) ? dependency.webacl.outputs.arn : null

  logging_config = try(values.logging_config, {})

  default_root_object = try(values.default_root_object, "index.html")

  tags = try(values.tags, {})
}