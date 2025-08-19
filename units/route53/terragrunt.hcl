include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-route53?ref=v5.0.0"
}

dependency "cloudfront" {
  config_path = values.cloudfront_path
  mock_outputs = {
    cloudfront_distribution_domain_name    = "d123456789.cloudfront.net"
    cloudfront_distribution_hosted_zone_id = "Z2FDTNDATAQYW2"
  }
}

dependency "route53_zones" {
  config_path  = values.route53_zones_path
  skip_outputs = try(values.route53_zones_path, null) == null ? true : false
  mock_outputs = {
    route53_zone_zone_id = {
      "yourdomain.com" = "Z123456789"
    }
  }
}

inputs = {
  zones = try(values.zones, {})

  records = concat(
    [
      for domain in try(values.domain_names, []) : {
        zone_id = try(values.hosted_zone_id, try(dependency.route53_zones.outputs.route53_zone_zone_id[values.primary_domain], null))
        name    = domain
        type    = "A"
        alias = {
          name    = dependency.cloudfront.outputs.cloudfront_distribution_domain_name
          zone_id = dependency.cloudfront.outputs.cloudfront_distribution_hosted_zone_id
        }
      }
    ],
    try(values.enable_ipv6, true) ? [
      for domain in try(values.domain_names, []) : {
        zone_id = try(values.hosted_zone_id, try(dependency.route53_zones.outputs.route53_zone_zone_id[values.primary_domain], null))
        name    = domain
        type    = "AAAA"
        alias = {
          name    = dependency.cloudfront.outputs.cloudfront_distribution_domain_name
          zone_id = dependency.cloudfront.outputs.cloudfront_distribution_hosted_zone_id
        }
      }
    ] : [],

    [
      for record in try(values.additional_records, []) : merge(record, {
        zone_id = try(record.zone_id, try(values.hosted_zone_id, try(dependency.route53_zones.outputs.route53_zone_zone_id[values.primary_domain], null)))
      })
    ]
  )

  tags = try(values.tags, {})
}