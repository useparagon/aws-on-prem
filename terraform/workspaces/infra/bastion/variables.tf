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

variable "vpc_id" {
  description = "The id of the VPC to create resources in."
}

variable "public_subnet" {
  description = "Public subnet accessible to the outside world."
}

variable "private_subnet" {
  description = "Private subnet accessible only within the VPC."
}

variable "ssh_whitelist" {
  description = "An optional list of IP addresses to whitelist ssh access."
  type        = list(string)
}

variable "force_destroy" {
  description = "Whether to enable force destroy."
  type        = bool
  default     = false
}

variable "eks_cluster" {
  description = "The EKS cluster that node groups and resources should be deployed to."
  type = object({
    name                               = string
    arn                                = string
    id                                 = string
    sg_id                              = string
    cluster_oidc_issuer_url            = string
    oidc_provider_arn                  = string
    cluster_endpoint                   = string
    cluster_certificate_authority_data = string
    worker_iam_role_arn                = string
    worker_iam_role_name               = string
  })
}

variable "cluster_super_admin" {
  description = "The IAM role created with super admin access to the cluster."
  type = object({
    arn  = string
    id   = string
    name = string
  })
}

locals {
  resource_group = "${var.workspace}-bastion"

  # TODO: update to random port for security
  ssh_port = 22
}
