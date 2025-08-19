include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-acm?ref=v6.0.0"
}

dependency "route53" {
  config_path = values.route53_path
  mock_outputs = {
    route53_zone_zone_id = {
      "yourdomain.com" = "Z1234567890ABC"
    }
  }
}

inputs = {
  domain_name = values.domain_name
  zone_id     = dependency.route53.outputs.route53_zone_zone_id[values.domain_name]

  subject_alternative_names = try(values.subject_alternative_names, [])
  wait_for_validation       = try(values.wait_for_validation, true)
  validation_method         = try(values.validation_method, "DNS")

  tags = try(values.tags, {})
}