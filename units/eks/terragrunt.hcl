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
  name               = values.name
  kubernetes_version = values.kubernetes_version

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  cluster_encryption_config = {
    provider_key_arn = dependency.kms.outputs.key_arn
    resources        = ["secrets"]
  }

  endpoint_public_access                   = values.endpoint_public_access
  enable_cluster_creator_admin_permissions = values.enable_cluster_creator_admin_permissions

  vpc_id                   = dependency.vpc.outputs.vpc_id
  subnet_ids               = dependency.vpc.outputs.private_subnets
  control_plane_subnet_ids = dependency.vpc.outputs.private_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = values.instance_types

      min_size     = values.min_size
      max_size     = values.max_size
      desired_size = values.desired_size
    }
  }

  authentication_mode = "API"

  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::${local.development_account_id}:role/terragrunt-execution-role"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = try(values.tags, {
    Name = "${local.project}-${local.env}-eks"
  })
}