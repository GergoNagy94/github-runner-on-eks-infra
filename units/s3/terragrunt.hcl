include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-s3-bucket?ref=v5.2.0"
}

inputs = {
  bucket  = values.bucket_name
  website = try(values.website, {})

  block_public_acls       = try(values.block_public_acls, false)
  block_public_policy     = try(values.block_public_policy, false)
  ignore_public_acls      = try(values.ignore_public_acls, false)
  restrict_public_buckets = try(values.restrict_public_buckets, false)

  attach_policy = try(values.attach_policy, false)
  policy        = try(values.policy, null)
  
  cors_rule = try(values.cors_rule, [])

  versioning = try(values.versioning, {
    enabled = false
  })

  server_side_encryption_configuration = try(values.server_side_encryption_configuration, {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  })
  lifecycle_rule                       = try(values.lifecycle_rule, [])
  tags                                 = try(values.tags, {})
}