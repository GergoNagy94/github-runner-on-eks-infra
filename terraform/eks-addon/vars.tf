variable "cluster_name" {
  type = string
}

variable "addon_name" {
  type = string
}

variable "addon_version" {
  type = string
}

variable "service_account_role_arn" {
  type = string
}

variable "resolve_conflicts_on_create" {
  type    = string
  default = "OVERWRITE"
}

variable "resolve_conflicts_on_update" {
  type    = string
  default = "OVERWRITE"
}

variable "tags" {
  type    = map(string)
  default = {}
}