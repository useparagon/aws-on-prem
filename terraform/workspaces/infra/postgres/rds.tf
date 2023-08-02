locals {
  postgres_family = "postgres${split(".", var.postgres_version)[0]}" // e.g. `postgres11`, `postgres12`, etc
}

resource "random_string" "postgres_root_username" {
  for_each = var.rds_restore_from_snapshot ? {} : local.postgres_instances

  length  = 16
  special = false
  numeric = false
  lower   = true
  upper   = true
}

resource "random_string" "postgres_root_password" {
  for_each = var.rds_restore_from_snapshot ? {} : local.postgres_instances

  length    = 16
  min_upper = 2
  min_lower = 2
  numeric   = true
  special   = false
  lower     = true
  upper     = true
}

resource "random_string" "snapshot_identifier" {
  count = var.rds_final_snapshot_enabled ? 1 : 0

  length  = 8
  numeric = false
  special = false
  lower   = true
  upper   = false
}

resource "aws_db_subnet_group" "postgres" {
  name        = "${var.workspace}-postgres-subnet"
  description = "${var.workspace} postgres subnet group"
  subnet_ids  = var.private_subnet.*.id

  tags = {
    Name = "${var.workspace}-postgres-subnet"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.workspace}-${local.postgres_family}"
  family = local.postgres_family

  dynamic "parameter" {
    for_each = [
      {
        name         = "log_statement"
        value        = "ddl"
        apply_method = "pending-reboot"
      },
      {
        name         = "log_min_duration_statement"
        value        = 1000
        apply_method = "pending-reboot"
      },
      {
        name         = "max_connections"
        value        = 10000
        apply_method = "pending-reboot"
      },
      {
        name         = "wal_buffers"
        value        = "2048" # sets `wal_buffers` to 16mb
        apply_method = "pending-reboot"
      },
    ]
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.workspace}-postgres-group"
  }
}

data "aws_db_snapshot" "postgres" {
  for_each = var.rds_restore_from_snapshot ? local.postgres_instances : {}

  db_instance_identifier = each.value.name
  snapshot_type          = "manual"
  most_recent            = true
}

resource "aws_db_instance" "postgres" {
  for_each = local.postgres_instances

  identifier = each.value.name
  db_name    = each.value.db
  port       = "5432"
  username   = var.rds_restore_from_snapshot ? null : random_string.postgres_root_username[each.key].result
  password   = var.rds_restore_from_snapshot ? null : random_string.postgres_root_password[each.key].result

  engine               = "postgres"
  engine_version       = var.postgres_version
  instance_class       = each.value.size
  parameter_group_name = aws_db_parameter_group.postgres.name
  storage_type         = "gp2"
  replicate_source_db  = null

  allocated_storage           = 20
  max_allocated_storage       = 1000
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  availability_zone           = var.multi_az_enabled ? null : var.availability_zones.names[0]
  backup_retention_period     = 7
  monitoring_interval         = 15
  multi_az                    = var.multi_az_enabled
  monitoring_role_arn         = aws_iam_role.rds_enhanced_monitoring.arn
  backup_window               = "06:00-07:00"
  maintenance_window          = "Tue:04:00-Tue:05:00"

  db_subnet_group_name      = aws_db_subnet_group.postgres.id
  vpc_security_group_ids    = [aws_security_group.postgres.id]
  publicly_accessible       = false
  deletion_protection       = !var.disable_deletion_protection
  snapshot_identifier       = var.rds_restore_from_snapshot ? data.aws_db_snapshot.postgres[each.key].id : null
  skip_final_snapshot       = !var.rds_final_snapshot_enabled
  final_snapshot_identifier = var.rds_final_snapshot_enabled ? "${each.value.name}-${random_string.snapshot_identifier[0].result}" : null
  storage_encrypted         = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 731
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  apply_immediately = true
}
