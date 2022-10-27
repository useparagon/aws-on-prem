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

locals {
  workspace = "paragon-enterprise-${random_string.app.result}"
}
