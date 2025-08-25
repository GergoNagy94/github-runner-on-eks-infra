include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../../../terraform/eks-addon"
}

dependency "eks" {
  config_path = values.eks_path
  mock_outputs = {
    cluster_name = "example-cluster"
  }
}

dependency "irsa" {
  config_path = values.irsa_path
  mock_outputs = {
    iam_role_arn = "arn:aws:iam::123456789012:role/example-role"
  }
}

inputs = {

  cluster_name                = dependency.eks.outputs.cluster_name
  addon_name                  = values.addon_name
  addon_version               = values.addon_version
  service_account_role_arn    = dependency.irsa.outputs.iam_role_arn
  resolve_conflicts_on_create = try(values.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(values.resolve_conflicts_on_update, "OVERWRITE")

  tags = try(values.tags, {
    Name = "${values.cluster_name}-${values.addon_name}-addon"
  })
}