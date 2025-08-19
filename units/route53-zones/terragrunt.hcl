include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-route53//modules/zones?ref=v5.0.0"
}

inputs = {
  zones = try(values.zones, {})
  tags  = try(values.tags, {})
}