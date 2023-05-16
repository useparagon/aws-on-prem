variable "workspace" {
  description = "The name of the workspace resources are being created in."
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
}

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

variable "disable_deletion_protection" {
  description = "Whether to disable deletion protection."
  type        = bool
}
