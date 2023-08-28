variable "workspace" {
  description = "The name of the workspace resources are being created in."
  type        = string
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region resources are created in."
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key for AWS account to provision resources on."
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for AWS account to provision resources on."
  type        = string
}

variable "aws_session_token" {
  description = "AWS session token."
  type        = string
}

variable "vpc" {
  description = "The VPC to create resources in."
}

variable "public_subnet" {
  description = "The public subnets within the VPC."
}

variable "private_subnet" {
  description = "The private subnets within the VPC."
}

variable "availability_zones" {
  description = "The AWS zones that are currently availabile."
}

variable "postgres_version" {
  description = "Postgres version for the database."
  type        = string
}

variable "rds_instance_class" {
  description = "The RDS instance class type used for Postgres."
}

variable "rds_restore_from_snapshot" {
  description = "Specifies that RDS instances should be restored from a snapshot."
  type        = bool
}

variable "rds_final_snapshot_enabled" {
  description = "Specifies that RDS instances should perform a final snapshot before being deleted."
  type        = bool
}

variable "disable_deletion_protection" {
  description = "Whether to disable deletion protection."
  type        = bool
}

variable "multi_az_enabled" {
  description = "Whether or not multi-az is enabled."
  type        = bool
}

variable "multi_postgres" {
  description = "Whether or not to create multiple Postgres instances."
  type        = bool
}

locals {
  postgres_instances = var.multi_postgres ? {
    beethoven = {
      name         = "${var.workspace}-beethoven"
      size         = var.rds_instance_class
      db           = "beethoven"
      storage_type = "gp2"
    }
    cerberus = {
      name         = "${var.workspace}-cerberus"
      size         = "db.t4g.micro"
      db           = "cerberus"
      storage_type = "gp2"
    }
    hermes = {
      name         = "${var.workspace}-hermes"
      size         = var.rds_instance_class
      db           = "hermes"
      storage_type = "gp3"
      iops         = 3000
    }
    zeus = {
      name         = "${var.workspace}-zeus"
      size         = "db.t4g.small"
      db           = "zeus"
      storage_type = "gp2"
    }
    } : {
    paragon = {
      name         = "${var.workspace}"
      size         = var.rds_instance_class
      db           = "postgres"
      storage_type = "gp2"
    }
  }
}
