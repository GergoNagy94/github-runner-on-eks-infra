include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-iam//modules/iam-role-for-service-accounts-eks?ref=v5.59.0"
}

dependency "eks" {
  config_path = values.eks_path
  mock_outputs = {
    cluster_name            = "mock-cluster"
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0000000000000000"
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
  role_name = try(values.role_name, "ebs-csi-driver")

  oidc_providers = {
    main = {
      provider_arn               = dependency.eks.outputs.oidc_provider_arn
      namespace_service_accounts = try(values.namespace_service_accounts, ["kube-system:ebs-csi-controller-sa"])
    }
  }

  attach_ebs_csi_policy = true

  ebs_csi_kms_cmk_ids = try(values.enable_kms_encryption, false) ? [dependency.kms.outputs.key_arn] : []

  tags = try(values.tags, {})
}