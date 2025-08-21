include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:aws-ia/terraform-aws-eks-blueprints-addon?ref=v1.1.1"
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
  contents = <<EOF
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
EOF
}

inputs = {
  create = true
  
  helm_config = {
    name       = "aws-load-balancer-controller"
    chart      = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    version    = "1.8.1"
    namespace  = "kube-system"
    
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
  
  oidc_providers = {
    this = {
      provider_arn = dependency.eks.outputs.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = try(values.tags, {
    Name = "${local.project}-${local.env}-aws-lbc"
  })
}