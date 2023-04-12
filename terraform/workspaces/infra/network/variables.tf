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

variable "az_count" {
  description = "Number of AZs to cover in a given region."
  type        = number
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = string
}

variable "vpc_cidr_newbits" {
  description = "Optional configuration for newbits used for calculating subnets."
  type        = number
}
