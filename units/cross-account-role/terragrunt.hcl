include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../../../terraform/cross-account-role"
}

inputs = {
  trusted_account_arn = values.trusted_account_arn
  eks_cross_account_role_name = values.eks_cross_account_role_name

  tags = try(values.tags, {
    Name        = "cross-account-role"
  })
}