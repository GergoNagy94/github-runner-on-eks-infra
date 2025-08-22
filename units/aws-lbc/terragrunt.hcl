include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:aws-ia/terraform-aws-eks-blueprints-addons?ref=v1.22.0"
}

dependency "eks" {
  config_path = values.eks_path
  mock_outputs = {
    cluster_name      = "mock-cluster"
    cluster_endpoint  = "https://mock-cluster-endpoint"
    cluster_version   = "1.33"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
  }
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}

generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster" "cluster" {
  name = "${dependency.eks.outputs.cluster_name}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${dependency.eks.outputs.cluster_name}"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }

  repository_config_path = "./.helm/repositories.yaml"
  repository_cache       = "./.helm"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
EOF
}

inputs = {
  enable_aws_load_balancer_controller = values.enable_aws_load_balancer_controller

  cluster_name      = dependency.eks.outputs.cluster_name
  cluster_endpoint  = dependency.eks.outputs.cluster_endpoint
  cluster_version   = dependency.eks.outputs.cluster_version
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn

  aws_load_balancer_controller = {
    chart_version = "1.8.1"
    set = [
      {
        name  = "clusterName"
        value = dependency.eks.outputs.cluster_name
      },
      {
        name  = "vpcId"
        value = dependency.vpc.outputs.vpc_id
      }
    ]
  }

  tags = try(values.tags, {
    Name = "${local.project}-${local.env}-aws-lbc"
  })
}
