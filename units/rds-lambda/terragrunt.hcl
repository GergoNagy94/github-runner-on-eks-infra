include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-rds?ref=v6.12.0"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id                     = "vpc-00000000"
    database_subnets           = ["subnet-00000000", "subnet-00000001"]
    database_subnet_group_name = "mock-db-subnet-group"
    vpc_cidr_block             = "10.0.0.0/16"
  }
}

# Secrets Manager dependency removed - RDS manages secrets automatically

dependency "security_group" {
  config_path = values.security_group_path
  mock_outputs = {
    security_group_id = "sg-00000000"
  }
}

inputs = {
  identifier = values.identifier

  engine               = try(values.engine, "mysql")
  engine_version       = try(values.engine_version, "8.0")
  major_engine_version = try(values.major_engine_version, "8.0")
  instance_class       = try(values.instance_class, "db.t3.micro")

  allocated_storage     = try(values.allocated_storage, 20)
  max_allocated_storage = try(values.max_allocated_storage, 100)
  storage_type          = try(values.storage_type, "gp3")
  storage_encrypted     = try(values.storage_encrypted, true)

  db_name  = try(values.db_name, "appdb")
  username = try(values.username, "dbadmin")

  manage_master_user_password   = try(values.manage_master_user_password, true)
  master_user_secret_kms_key_id = try(values.master_user_secret_kms_key_id, null)

  vpc_security_group_ids = [dependency.security_group.outputs.security_group_id]
  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group_name

  family                    = try(values.family, "mysql8.0")
  create_db_parameter_group = try(values.create_db_parameter_group, true)
  create_db_option_group    = try(values.create_db_option_group, false)

  backup_retention_period = try(values.backup_retention_period, 7)
  backup_window           = try(values.backup_window, "03:00-04:00")
  maintenance_window      = try(values.maintenance_window, "sun:04:00-sun:05:00")

  monitoring_interval    = try(values.monitoring_interval, 60)
  monitoring_role_arn    = try(values.monitoring_role_arn, null)
  create_monitoring_role = try(values.create_monitoring_role, true)

  performance_insights_enabled          = try(values.performance_insights_enabled, true)
  performance_insights_retention_period = try(values.performance_insights_retention_period, 7)

  deletion_protection              = try(values.deletion_protection, false)
  skip_final_snapshot              = try(values.skip_final_snapshot, true)
  final_snapshot_identifier_prefix = try(values.final_snapshot_identifier_prefix, "final")

  multi_az = try(values.multi_az, false)

  parameters = try(values.parameters, [
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    }
  ])

  tags = try(values.tags, {})
}

