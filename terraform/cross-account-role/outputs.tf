output "role_arn" {
  description = "The ARN of the IAM role created for cross-account access."
  value       = aws_iam_role.eks_cross_account.arn
}

output "role_name" {
  description = "The name of the IAM role created for cross-account access."
  value       = aws_iam_role.eks_cross_account.name
}