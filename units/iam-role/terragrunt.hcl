include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-iam//modules/iam-role-for-service-accounts-eks?ref=v5.59.0"
}

dependency "eks" {
  config_path = values.eks_path
  mock_outputs = {
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
  }
}

inputs = {
  role_name = values.role_name

  oidc_providers = {
    main = {
      provider_arn               = dependency.eks.outputs.oidc_provider_arn
      namespace_service_accounts = try(values.namespace_service_accounts, [])
    }
  }

  attach_aws_load_balancer_controller_policy = try(values.attach_aws_load_balancer_controller_policy, false)
  attach_external_dns_policy                 = try(values.attach_external_dns_policy, false)
  attach_external_secrets_policy             = try(values.attach_external_secrets_policy, false)
  attach_cert_manager_policy                 = try(values.attach_cert_manager_policy, false)
  attach_cluster_autoscaler_policy           = try(values.attach_cluster_autoscaler_policy, false)
  attach_ebs_csi_policy                      = try(values.attach_ebs_csi_policy, false)
  attach_efs_csi_policy                      = try(values.attach_efs_csi_policy, false)
  attach_fsx_lustre_csi_policy               = try(values.attach_fsx_lustre_csi_policy, false)
  attach_vpc_cni_policy                      = try(values.attach_vpc_cni_policy, false)

  role_policy_arns = try(values.role_policy_arns, {})

  allow_self_assume_role = try(values.allow_self_assume_role, false)

  tags = try(values.tags, {})
}