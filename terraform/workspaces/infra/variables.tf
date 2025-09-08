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

variable "organization" {
  description = "Optional configuration to override resource names."
  type        = string
  default     = null
}

variable "az_count" {
  description = "Number of AZs to cover in a given region."
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_newbits" {
  description = "Optional configuration for newbits used for calculating subnets."
  type        = number
  default     = 8
}

variable "rds_instance_class" {
  description = "The RDS instance class type used for Postgres."
  type        = string
  default     = "db.t4g.small"
}

variable "rds_restore_from_snapshot" {
  description = "Specifies that RDS instances should be restored from a snapshot."
  type        = bool
  default     = false
}

variable "rds_final_snapshot_enabled" {
  description = "Specifies that RDS instances should perform a final snapshot before being deleted."
  type        = bool
  default     = true
}

variable "elasticache_node_type" {
  description = "The ElastiCache node type used for Redis."
  type        = string
  default     = "cache.r6g.large"
}

variable "postgres_version" {
  description = "Postgres version for the database."
  type        = string
  default     = "16"
}

variable "multi_postgres" {
  description = "Whether or not to create multiple Postgres instances."
  type        = bool
  default     = false
}

variable "master_guardduty_account_id" {
  description = "Optional AWS account id to delegate GuardDuty control to."
  type        = string
  default     = null
}

variable "mfa_enabled" {
  description = "Whether to require MFA for certain configurations (e.g. cloudtrail s3 bucket deletion)"
  type        = bool
  default     = false
}

variable "ssh_whitelist" {
  description = "An optional list of IP addresses to whitelist ssh access."
  type        = string
  default     = ""
}

variable "disable_cloudtrail" {
  description = "Used to specify that Cloudtrail is disabled."
  type        = bool
  default     = false
}

variable "disable_deletion_protection" {
  description = "Used to disable deletion protection on RDS and S3 resources."
  type        = bool
  default     = false
}

variable "disable_logs" {
  description = "Whether to disable system level log gathering."
  type        = bool
  default     = false
}

variable "app_bucket_expiration" {
  description = "The number of days to retain S3 app data before deleting"
  type        = number
  default     = 90
}

variable "multi_az_enabled" {
  description = "Whether or not to enable multi-az."
  type        = bool
  default     = true
}

variable "multi_redis" {
  description = "Whether or not to create multiple Redis instances. Used for high-volume installations."
  type        = bool
  default     = false
}

variable "k8_version" {
  description = "The version of Kubernetes to run in the cluster."
  type        = string
  default     = "1.32"
}

variable "k8_ondemand_node_instance_type" {
  description = "The compute instance type to use for Kubernetes nodes."
  type        = string
  default     = "m6a.xlarge"
}

variable "k8_spot_node_instance_type" {
  description = "The compute instance type to use for Kubernetes spot nodes."
  type        = string
  default     = "t3a.xlarge,t3.xlarge,m5a.xlarge,m5.xlarge,m6a.xlarge,m6i.xlarge,m7a.xlarge,m7i.xlarge,r5a.xlarge,m4.xlarge"
}

variable "k8_spot_instance_percent" {
  description = "The percentage of spot instances to use for Kubernetes nodes."
  type        = number
  default     = 75
  validation {
    condition     = var.k8_spot_instance_percent >= 0 && var.k8_spot_instance_percent <= 100
    error_message = "Value must be between 0 - 100."
  }
}

variable "k8_min_node_count" {
  description = "The minimum number of nodes to run in the Kubernetes cluster."
  type        = number
  default     = 4
}

variable "k8_max_node_count" {
  description = "The maximum number of nodes to run in the Kubernetes cluster."
  type        = number
  default     = 20
}

variable "eks_addon_ebs_csi_driver_enabled" {
  # Should be on for Kubernetes >= 1.23, but optional for backwards compatability for manually migrated installations.
  description = "Whether or not to enable AWS CSI Driver addon."
  type        = bool
  default     = true
}

variable "eks_admin_user_arns" {
  # If these aren't available when the cluster is first initialized, it'll have to be manually created
  description = "Comma-separated list of ARNs for IAM roles that should have admin access to cluster. Used for viewing cluster resources in AWS dashboard or running kubectl commands."
  type        = string
  default     = null
}

variable "eks_admin_role_arns" {
  # If these aren't available when the cluster is first initialized, it'll have to be manually created
  # https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
  description = "Comma-separated list of ARNs for IAM roles that should have admin access to cluster. Used for viewing cluster resources in AWS dashboard."
  type        = string
  default     = null
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

variable "cloudflare_dns_api_token" {
  description = "Cloudflare DNS API token for SSL certificate creation and verification."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id to set CNAMEs."
  type        = string
  default     = null
}

variable "kms_admin_role" {
  description = "ARN of IAM role allowed to administer KMS keys."
  type        = string
  default     = null
}

variable "create_autoscaling_linked_role" {
  description = "Whether or not to create an IAM role for autoscaling."
  type        = bool
  default     = true
}

variable "managed_sync_enabled" {
  description = "Whether to enable managed sync."
  type        = bool
  default     = false
}

variable "msk_kafka_version" {
  description = "The Kafka version for the MSK cluster."
  type        = string
  // NOTE: to use a small instance type like `kafka.t3.small`, we need to use an older version that uses zookeeper
  // we're default to an older version to keep costs low, but we can override this if we use a supported larger instance type
  default = "3.6.0"
}

variable "msk_kafka_num_broker_nodes" {
  description = "The number of broker nodes for the MSK cluster."
  type        = number
  default     = 3
}

variable "msk_instance_type" {
  description = "The instance type for the MSK cluster."
  type        = string
  default     = "kafka.t3.small"
}

locals {
  workspace   = "paragon-enterprise-${var.organization != null ? var.organization : random_string.app[0].result}"
  environment = "enterprise"

  default_tags = {
    Name        = local.workspace
    Environment = local.environment
    Workspace   = local.workspace
    Creator     = "Terraform"
  }

  // get distinct values from comma-separated list, filter empty values and trim them
  // for `ip_whitelist`, if an ip doesn't contain a range at the end (e.g. `<IP_ADDRESS>/32`), then add `/32` to the end. `1.1.1.1` becomes `1.1.1.1/32`; `2.2.2.2/24` remains unchanged
  ssh_whitelist = distinct([for value in split(",", var.ssh_whitelist) : "${trimspace(value)}${replace(value, "/", "") != value ? "" : "/32"}" if trimspace(value) != ""])

  // split instance types by comma, trim, and remove duplicates
  k8_ondemand_node_instance_type = distinct([for value in split(",", var.k8_ondemand_node_instance_type) : trimspace(value)])
  k8_spot_node_instance_type     = distinct([for value in split(",", var.k8_spot_node_instance_type) : trimspace(value)])

  // split ARNs by comma, trim, remove duplicates, and transform into object
  eks_admin_user_arns = var.eks_admin_user_arns == null ? [] : [
    for value in distinct([for value in split(",", var.eks_admin_user_arns) : trimspace(value)]) : {
      userarn  = value
      username = element(split("/", value), length(split("/", value)) - 1)
      groups   = ["system:masters"]
    }
  ]

  // split ARNs by comma, trim, remove duplicates, and transform into object
  eks_admin_role_arns = var.eks_admin_role_arns == null ? [] : [
    for value in distinct([for value in split(",", var.eks_admin_role_arns) : trimspace(value)]) : {
      rolearn  = value
      username = element(split("/", value), length(split("/", value)) - 1)
      groups   = ["system:masters"]
    }
  ]
}
