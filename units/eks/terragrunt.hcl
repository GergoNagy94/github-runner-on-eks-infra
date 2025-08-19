include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-eks?ref=v20.37.1"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id          = "vpc-00000000"
    private_subnets = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
    vpc_cidr_block  = "10.0.0.0/16"
  }
}

dependency "kms" {
  config_path  = values.kms_path
  skip_outputs = try(values.enable_kms_encryption, false) ? false : true
  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

inputs = {
  cluster_name    = values.cluster_name
  cluster_version = try(values.cluster_version, "1.31")

  bootstrap_self_managed_addons = try(values.bootstrap_self_managed_addons, true)

  cluster_endpoint_public_access       = try(values.cluster_endpoint_public_access, true)
  cluster_endpoint_private_access      = try(values.cluster_endpoint_private_access, true)
  cluster_endpoint_public_access_cidrs = try(values.cluster_endpoint_public_access_cidrs, ["0.0.0.0/0"])

  vpc_id                   = dependency.vpc.outputs.vpc_id
  subnet_ids               = dependency.vpc.outputs.private_subnets
  control_plane_subnet_ids = dependency.vpc.outputs.private_subnets

  cluster_encryption_config = try(values.enable_kms_encryption, false) ? {
    provider_key_arn = dependency.kms.outputs.key_arn
    resources        = ["secrets"]
  } : {
    provider_key_arn = null
    resources        = []
  }

  authentication_mode = try(values.authentication_mode, "API_AND_CONFIG_MAP")

  access_entries = try(values.access_entries, {})

  enable_irsa = try(values.enable_irsa, true)

  cluster_enabled_log_types              = try(values.cluster_enabled_log_types, ["api", "audit", "authenticator", "controllerManager", "scheduler"])
  cloudwatch_log_group_retention_in_days = try(values.cloudwatch_log_group_retention_in_days, 14)
  create_cloudwatch_log_group            = try(values.create_cloudwatch_log_group, true)

  eks_managed_node_groups = try(values.enable_auto_mode, true) ? {} : try(values.eks_managed_node_groups, {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]

      labels = {
        Environment = "development"
        NodeGroup   = "default"
      }
    }
  })

  cluster_addons = try(values.enable_auto_mode, true) ? {
    coredns = {
      preserve    = true
      most_recent = true
    }
    eks-pod-identity-agent = {
      preserve    = true
      most_recent = true
    }
    kube-proxy = {
      preserve    = true
      most_recent = true
    }
    vpc-cni = {
      preserve    = true
      most_recent = true
    }
  } : try(values.cluster_addons, {})

  compute_config = try(values.enable_auto_mode, true) ? {
    enabled       = true
    node_pools    = try(values.node_pools, ["general-purpose"])
    node_role_arn = try(values.node_role_arn, null)
  } : null

  storage_config = try(values.enable_auto_mode, true) ? {
    block_storage = {
      enabled = true
    }
  } : null

  cluster_security_group_additional_rules = try(values.cluster_security_group_additional_rules, {})
  node_security_group_additional_rules    = try(values.node_security_group_additional_rules, {})

  tags = try(values.tags, {})
}