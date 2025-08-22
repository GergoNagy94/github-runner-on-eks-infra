locals {
  env             = "development"
  region          = "eu-central-1"
  project         = "eks-runner"
  project_version = "1.0.0"

  development_account_id    = "567749996660"
  development_account_email = "gergodevops@gmail.com"
  organization_id           = "o-0000000000"
  organization_root_id      = "r-0000"
}

unit "vpc" {
  source = "../../../../../units/vpc"
  path   = "vpc"

  values = {
    name = "${local.project}-${local.env}-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["${local.region}a", "${local.region}b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_flow_log                      = false
    create_flow_log_cloudwatch_iam_role  = false
    create_flow_log_cloudwatch_log_group = false


    cluster_name = "${local.project}-${local.env}-cluster"


    tags = {
      Name      = "${local.project}-${local.env}-vpc"
      ManagedBy = "Terragrunt"
    }
  }
}

unit "kms" {
  source = "../../../../../units/kms"
  path   = "kms"

  values = {
    description = "KMS key for EKS cluster encryption"
    aliases     = ["alias/eks-cluster-encryption-terragrunt"]

    key_administrators = [
      "arn:aws:iam::${local.development_account_id}:root",
      "arn:aws:iam::${local.development_account_id}:role/terragrunt-execution-role"
    ]

    deletion_window_in_days = 7

    tags = {
      Name    = "eks-cluster-kms-key"
      Purpose = "EKS-Encryption"
    }
  }
}

unit "cross-account-role-gellert" {
  source = "../../../../../units/cross-account-role"
  path = "cross-account-role-gellert"

  values = {
    trusted_account_arn = "arn:aws:iam::555458747175:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_AdminAccess_18d3e6876e41f66a"
    eks_cross_account_role_name = "gellert-eks-cross-account-access"
  }
}

unit "eks" {
  source = "../../../../../units/eks"
  path   = "eks"

  values = {
    vpc_path = "../vpc"
    kms_path = "../kms"

    name               = "${local.env}-eks"
    kubernetes_version = "1.33"

    endpoint_public_access                   = true
    enable_cluster_creator_admin_permissions = true

    access_entries = {
      test = {
        principal_arn = "arn:aws:iam::567749996660:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_AdminAccess_6d73bc836f311973"

        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              namespace = []
              type      = "cluster"
            }
          }
        }
      },
      cross-accoount = {
        principal_arn = "arn:aws:iam::567749996660:role/gellert-eks-cross-account-access"

        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              namespace = []
              type      = "cluster"
            }
          }
        }
      }
    }

    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 3
    desired_size   = 2

    tags = {
      Name    = "${local.env}-eks"
      EKSMode = "Managed"
    }
  }
}

unit "aws-lbc" {
  source = "../../../../../units/aws-lbc"
  path   = "aws-lbc"

  values = {
    enable_aws_load_balancer_controller = true

    eks_path = "../eks"
    vpc_path = "../vpc"

    tags = {
      Name = "${local.project}-${local.env}-aws-lbc"
    }
  }
}