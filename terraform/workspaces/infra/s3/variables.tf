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

variable "cloudtrail_s3_bucket" {
  description = "The S3 bucket created by cloudtrail"
}

variable "force_destroy" {
  description = "Whether to enable force destroy."
  type        = bool
}

variable "app_bucket_expiration" {
  description = "The number of days to retain S3 app data before deleting"
}

variable "disable_cloudtrail" {
  description = "Used to specify that Cloudtrail is disabled."
  type        = bool
}

variable "disable_logs" {
  description = "Whether to disable system level log gathering."
  type        = bool
}

variable "managed_sync_enabled" {
  description = "Whether to enable managed sync."
  type        = bool
}
