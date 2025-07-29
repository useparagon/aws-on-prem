variable "app_name" {
  description = "An optional name to override the name of the resources created."
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production)."
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

# Cloudflare variables
variable "cloudflare_api_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens. Requires Edit permissions on Account `Cloudflare Tunnel`, `Access: Organizations, Identity Providers, and Groups`, `Access: Apps and Policies` and Zone `DNS`"
  type        = string
  sensitive   = true
  default     = "dummy-cloudflare-tokens-must-be-40-chars"
}

variable "cloudflare_tunnel_enabled" {
  description = "Flag whether to enable Cloudflare Zero Trust tunnel for bastion"
  type        = bool
  default     = false
}

variable "cloudflare_tunnel_subdomain" {
  description = "Subdomain under the Cloudflare Zone to create the tunnel"
  type        = string
  default     = ""
}

variable "cloudflare_tunnel_zone_id" {
  description = "Zone ID for Cloudflare domain"
  type        = string
  default     = ""
}

variable "cloudflare_tunnel_account_id" {
  description = "Account ID for Cloudflare account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_tunnel_email_domain" {
  description = "Email domain for Cloudflare access"
  type        = string
  sensitive   = true
  default     = "useparagon.com"
}

variable "eks_cluster_name" {
  description = "The EKS cluster that node groups and resources should be deployed to."
  type        = string
}

variable "default_tags" {
  description = "The default tags applied to resources."
  type        = map(string)
}

variable "enabled" {
  description = "Whether to enable the bastion."
  type        = bool
  default     = true
}

locals {
  resource_group = "${var.app_name}-bastion"

  cloudflare_tunnel_enabled = var.cloudflare_tunnel_enabled && var.enabled

  default_tags = merge(var.default_tags, {
    Name          = local.resource_group
    ResourceGroup = local.resource_group
  })

  ssh_port = 22
}
