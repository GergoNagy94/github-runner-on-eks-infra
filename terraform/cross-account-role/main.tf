resource "aws_iam_role" "eks_cross_account" {
  name = var.eks_cross_account_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_arn
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