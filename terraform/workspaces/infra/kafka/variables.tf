variable "workspace" {
  description = "The name of the workspace resources are being created in."
  type        = string
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

variable "vpc_id" {
  description = "VPC ID where the MSK cluster will be created"
  type        = string
}

variable "force_destroy" {
  description = "Whether to enable force destroy."
  type        = bool
}

variable "private_subnet" {
  description = "The private subnets within the VPC."
}

variable "msk_instance_type" {
  description = "The instance type for the MSK cluster."
  type        = string
}

variable "msk_kafka_version" {
  description = "The Kafka version for the MSK cluster."
  type        = string
}

variable "msk_kafka_num_broker_nodes" {
  description = "The number of broker nodes for the MSK cluster."
  type        = number
}
