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

    instance_types = ["m3.medium"]
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
    eks_path = "../eks"
    vpc_path = "../vpc"

    enable_aws_load_balancer_controller = true

    tags = {
      Name    = "${local.project}-${local.env}-aws-lbc"
    }
  }
}
