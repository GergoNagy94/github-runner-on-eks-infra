include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-security-group?ref=v5.1.2"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id         = "vpc-00000000"
    vpc_cidr_block = "10.0.0.0/16"
  }
}

inputs = {
  name        = values.name
  description = try(values.description, "Security group")
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = try(values.ingress_with_cidr_blocks, [])
  egress_with_cidr_blocks  = try(values.egress_with_cidr_blocks, [])

  tags = try(values.tags, {})
}