variable "aws_region" {
  description = "The AWS region resources are created in."
}

variable "aws_access_key_id" {
  description = "AWS Access Key for AWS account to provision resources on."
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for AWS account to provision resources on."
}

variable "aws_session_token" {
  description = "AWS session token."
  default     = null
}

variable "az_count" {
  description = "Number of AZs to cover in a given region."
  default     = "2"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  default     = "10.0.0.0/16"
}

variable "rds_instance_class" {
  description = "The RDS instance class type used for Postgres."
  type        = string
  default     = "db.t3.small"
}

variable "elasticache_node_type" {
  description = "The ElastiCache node type used for Redis."
  type        = string
  default     = "cache.t4g.medium"
}

variable "postgres_version" {
  description = "Postgres version for the database."
  type        = string
  default     = "12.7"
}

locals {
  workspace   = "paragon-enterprise-${random_string.app.result}"
  environment = "enterprise"
}
