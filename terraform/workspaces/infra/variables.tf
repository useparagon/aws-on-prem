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
  default     = "db.t3.small"
}

variable "elasticache_node_type" {
  description = "The ElastiCache node type used for Redis."
  type        = string
  default     = "cache.r6g.large"
}

variable "postgres_version" {
  description = "Postgres version for the database."
  type        = string
  default     = "12.7"
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
  default     = 365
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
  default     = "1.25"
}

variable "k8_ondemand_node_instance_type" {
  description = "The compute instance type to use for Kubernetes nodes."
  type        = string
  default     = "t3a.medium,t3.medium"
}

variable "k8_spot_node_instance_type" {
  description = "The compute instance type to use for Kubernetes spot nodes."
  type        = string
  default     = "t3a.medium,t3.medium"
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
  default     = 12
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
  # https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
  description = "Comma-separated list of ARNs for IAM users that should have admin access to cluster. Used for viewing cluster resources in AWS dashboard."
  type        = string
  default     = null
}

locals {
  workspace   = "paragon-enterprise-${var.organization != null ? var.organization : random_string.app[0].result}"
  environment = "enterprise"

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
}
