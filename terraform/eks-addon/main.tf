resource "aws_eks_addon" "this" {
  cluster_name             = var.cluster_name
  addon_name               = var.addon_name
  addon_version            = var.addon_version
  service_account_role_arn = var.service_account_role_arn

  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.resolve_conflicts_on_update

  tags = try(var.tags, {})
}
