resource "aws_iam_role" "eks_cross_account" {
  name = "eks-cross-account-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.principal_arn
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eks_cross_account_policy" {
  name = "EKSAccess"
  role = aws_iam_role.eks_cross_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      }
    ]
  })
}