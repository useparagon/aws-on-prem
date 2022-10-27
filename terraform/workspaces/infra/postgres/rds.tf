locals {
  postgres_family = "postgres${split(".", var.postgres_version)[0]}" // e.g. `postgres11`, `postgres12`, etc
}

resource "random_string" "postgres_root_username" {
  length  = 16
  special = false
  numeric = false
  lower   = true
  upper   = true
}

resource "random_string" "postgres_root_password" {
  length    = 16
  min_upper = 2
  min_lower = 2
  numeric   = true
  special   = false
  lower     = true
  upper     = true
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

resource "aws_db_instance" "postgres" {
  identifier = var.workspace
  name       = "postgres"
  port       = "5432"
  username   = random_string.postgres_root_username.result
  password   = random_string.postgres_root_password.result

  engine               = "postgres"
  engine_version       = var.postgres_version
  instance_class       = var.rds_instance_class
  parameter_group_name = aws_db_parameter_group.postgres.name
  storage_type         = "gp2"
  replicate_source_db  = null

  allocated_storage           = 20
  max_allocated_storage       = 1000
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  availability_zone           = var.availability_zones.names[0]
  backup_retention_period     = 7
  monitoring_interval         = 15
  multi_az                    = false
  monitoring_role_arn         = aws_iam_role.rds_enhanced_monitoring.arn
  backup_window               = "06:00-07:00"
  maintenance_window          = "Tue:04:00-Tue:05:00"

  db_subnet_group_name      = aws_db_subnet_group.postgres.id
  vpc_security_group_ids    = [aws_security_group.postgres.id]
  publicly_accessible       = false
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = var.workspace
  storage_encrypted         = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 731
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  apply_immediately = true
}
