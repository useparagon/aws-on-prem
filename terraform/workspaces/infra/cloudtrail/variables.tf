variable "workspace" {
  description = "The name of the workspace resources are being created in."
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
}

variable "aws_access_key_id" {
  description = "AWS Access Key for AWS account to provision resources on."
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for AWS account to provision resources on."
}

variable "aws_region" {
  description = "The AWS region resources are created in."
}

variable "aws_session_token" {
  description = "AWS session token."
}

variable "master_guardduty_account_id" {
  description = "Optional AWS account id to delegate GuardDuty control to."
  type        = string
}

variable "mfa_enabled" {
  description = "Whether to require MFA for certain configurations (e.g. cloudtrail s3 bucket deletion)"
  type        = bool
}

locals {
  cloudtrail_name           = "${var.workspace}-cloudtrail"
  cloudwatch_log_group_name = "${var.workspace}-cloudtrail-events"
}
