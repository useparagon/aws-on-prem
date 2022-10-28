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
  default     = null
}

variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "public_subnet_ids" {
  description = "A comma-delimited list of the public subnet ids."
  type        = string
}

variable "private_subnet_ids" {
  description = "A comma-delimited list of the private subnet ids."
  type        = string
}

variable "helm_values" {
  description = "Object containing values values to pass to the helm chart."
  type = map(any)
}

locals {
  public_subnet_ids  = distinct([for value in split(",", var.public_subnet_ids) : trimspace(value)])
  private_subnet_ids = distinct([for value in split(",", var.public_subnet_ids) : trimspace(value)])
}