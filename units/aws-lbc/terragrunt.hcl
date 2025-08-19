include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:DNXLabs/terraform-aws-eks-lb-controller?ref=0.11.0"
}

dependency "eks" {
  config_path = values.eks_path
  mock_outputs = {
    cluster_name            = "mock-cluster"
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
  }
}

inputs = {
  cluster_name                     = dependency.eks.outputs.cluster_name
  cluster_identity_oidc_issuer     = dependency.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.oidc_provider_arn

  helm_chart_name         = try(values.helm_chart_name, "aws-load-balancer-controller")
  helm_chart_release_name = try(values.helm_chart_release_name, "aws-load-balancer-controller")
  helm_chart_repo         = try(values.helm_chart_repo, "https://aws.github.io/eks-charts")
  helm_chart_version      = try(values.helm_chart_version, "1.8.4")

  namespace            = try(values.namespace, "kube-system")
  service_account_name = try(values.service_account_name, "aws-load-balancer-controller")

  helm_chart_values = try(values.helm_chart_values, [])

  irsa_role_name_prefix = try(values.irsa_role_name_prefix, "aws-load-balancer-controller")

  tags = try(values.tags, {})
}