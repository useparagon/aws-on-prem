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

variable "vpc" {
  description = "The VPC to create resources in."
}

variable "public_subnet" {
  description = "The public subnets within the VPC."
}

variable "private_subnet" {
  description = "The private subnets within the VPC."
}

variable "elasticache_node_type" {
  description = "The ElastiCache node type used for Redis."
  type        = string
}

variable "multi_az_enabled" {
  description = "Whether or not multi-az is enabled."
  type        = bool
}

variable "multi_redis" {
  description = "Whether or not to create multiple Redis instances."
  type        = bool
}

locals {
  redis_instances = var.multi_redis ? {
    cache = {
      cluster = true
      size    = var.elasticache_node_type
    }
    queue = {
      cluster = false
      size    = "cache.t4g.medium"
    }
    system = {
      cluster = false
      size    = "cache.t3.micro"
    }
    } : {
    cache = {
      cluster = false
      size    = var.elasticache_node_type
    }
  }

  # https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutoScaling.html
  # only R5, R6g, M5, M6g families supported
  cache_autoscaling_supports_family = contains(["r5", "r6g", "m5", "m6g"], element(split(".", lower(var.elasticache_node_type)), 1))
  # only large, xlarge, and 2xlarge supported
  cache_autoscaling_supports_size = contains(["large", "xlarge", "2xlarge"], element(split(".", lower(var.elasticache_node_type)), 2))
  cache_autoscaling_enabled       = var.multi_redis && local.cache_autoscaling_supports_family && local.cache_autoscaling_supports_size

  redis_instances_standalone = {
    for key, value in local.redis_instances :
    key => value
    if value.cluster == false
  }

  redis_version = "6.x"
}
