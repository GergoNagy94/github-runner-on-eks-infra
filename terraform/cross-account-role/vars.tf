variable "trusted_account_arn" {
  description = "List of trusted account ARNs that can assume the EKS cross-account role"
  type        = string
}

variable "eks_cross_account_role_name" {
  description = "The name of the EKS cross-account role"
  type        = string
}