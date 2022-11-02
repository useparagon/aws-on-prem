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
  description = "The name of the organization that's deploying Paragon."
  type        = string
}

variable "domain" {
  description = "The root domain used for the microservices."
  type        = string
}

variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
  type        = string
  default     = "enterprsie"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "docker_username" {
  description = "Docker username to pull images."
  type        = string
}

variable "docker_password" {
  description = "Docker password to pull images."
  type        = string
}

variable "docker_email" {
  description = "Docker password to pull images."
  type        = string
}

variable "helm_values" {
  description = "Object containing values values to pass to the helm chart."
  type        = map(any)
}

locals {
  microservices = {
    "cerberus" = {
      "port"             = lookup(var.helm_values, "CERBERUS_PORT", 1700)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "CERBERUS_PUBLIC_URL", "https://cerberus.${var.domain}")
    }
    "connect" = {
      "port"             = lookup(var.helm_values, "CONNECT_PORT", 1707)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "CONNECT_PUBLIC_URL", "https://connect.${var.domain}")
    }
    "dashboard" = {
      "port"             = lookup(var.helm_values, "DASHBOARD_PORT", 1704)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "DASHBOARD_PUBLIC_URL", "https://dashboard.${var.domain}")
    }
    "hercules" = {
      "port"             = lookup(var.helm_values, "HERCULES_PORT", 1701)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "HERCULES_PUBLIC_URL", "https://hercules.${var.domain}")
    }
    "hermes" = {
      "port"             = lookup(var.helm_values, "HERMES_PORT", 1702)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "HERMES_PUBLIC_URL", "https://hermes.${var.domain}")
    }
    "minio" = {
      "port"             = lookup(var.helm_values, "MINIO_PORT", 9000)
      "healthcheck_path" = "/minio/health/live"
      "public_url"       = lookup(var.helm_values, "MINIO_PUBLIC_URL", "https://minio.${var.domain}")
    }
    "passport" = {
      "port"             = lookup(var.helm_values, "PASSPORT_PORT", 1706)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "PASSPORT_PUBLIC_URL", "https://passport.${var.domain}")
    }
    "zeus" = {
      "port"             = lookup(var.helm_values, "ZEUS_PORT", 1703)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values, "ZEUS_PUBLIC_URL", "https://zeus.${var.domain}")
    }
  }


  helm_keys_to_remove = [
    "POSTGRES_HOST",
    "POSTGRES_PORT",
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_DATABASE",
    "REDIS_HOST",
    "REDIS_PORT",
  ]

  helm_values = {
    for key, value in merge({
      // default values, can be overridden by `.env-helm`
      NODE_ENV              = "production"
      PLATFORM_ENV          = "enterprise"
      BRANCH                = "master"
      SENDGRID_API_KEY      = "SG.xxx"
      SENDGRID_FROM_ADDRESS = "not-a-real@email.com"

      CERBERUS_PUBLIC_URL  = local.microservices.cerberus.public_url
      CONNECT_PUBLIC_URL   = local.microservices.connect.public_url
      DASHBOARD_PUBLIC_URL = local.microservices.dashboard.public_url
      HERCULES_PUBLIC_URL  = local.microservices.hercules.public_url
      HERMES_PUBLIC_URL    = local.microservices.hermes.public_url
      MINIO_PUBLIC_URL     = local.microservices.minio.public_url
      PASSPORT_PUBLIC_URL  = local.microservices.passport.public_url
      ZEUS_PUBLIC_URL      = local.microservices.zeus.public_url
      },
      // custom values provided in `.env-helm`, overrides default values
      var.helm_values,
      {
        // transformations, take priority over `.env-helm`
        AWS_REGION   = var.aws_region
        REGION       = var.aws_region
        ORGANIZATION = var.organization
        HOST_ENV     = "AWS_K8"

        ADMIN_BASIC_AUTH_USERNAME = var.helm_values["LICENSE"]
        ADMIN_BASIC_AUTH_PASSWORD = var.helm_values["LICENSE"]

        BEETHOVEN_POSTGRES_HOST     = var.helm_values["POSTGRES_HOST"]
        BEETHOVEN_POSTGRES_PORT     = var.helm_values["POSTGRES_PORT"]
        BEETHOVEN_POSTGRES_USERNAME = var.helm_values["POSTGRES_USER"]
        BEETHOVEN_POSTGRES_PASSWORD = var.helm_values["POSTGRES_PASSWORD"]
        BEETHOVEN_POSTGRES_DATABASE = var.helm_values["POSTGRES_DATABASE"]
        CERBERUS_POSTGRES_HOST      = var.helm_values["POSTGRES_HOST"]
        CERBERUS_POSTGRES_PORT      = var.helm_values["POSTGRES_PORT"]
        CERBERUS_POSTGRES_USERNAME  = var.helm_values["POSTGRES_USER"]
        CERBERUS_POSTGRES_PASSWORD  = var.helm_values["POSTGRES_PASSWORD"]
        CERBERUS_POSTGRES_DATABASE  = var.helm_values["POSTGRES_DATABASE"]
        HERMES_POSTGRES_HOST        = var.helm_values["POSTGRES_HOST"]
        HERMES_POSTGRES_PORT        = var.helm_values["POSTGRES_PORT"]
        HERMES_POSTGRES_USERNAME    = var.helm_values["POSTGRES_USER"]
        HERMES_POSTGRES_PASSWORD    = var.helm_values["POSTGRES_PASSWORD"]
        HERMES_POSTGRES_DATABASE    = var.helm_values["POSTGRES_DATABASE"]
        ZEUS_POSTGRES_HOST          = var.helm_values["POSTGRES_HOST"]
        ZEUS_POSTGRES_PORT          = var.helm_values["POSTGRES_PORT"]
        ZEUS_POSTGRES_USERNAME      = var.helm_values["POSTGRES_USER"]
        ZEUS_POSTGRES_PASSWORD      = var.helm_values["POSTGRES_PASSWORD"]
        ZEUS_POSTGRES_DATABASE      = var.helm_values["POSTGRES_DATABASE"]

        REDIS_URL                      = "${var.helm_values["REDIS_HOST"]}:${var.helm_values["REDIS_PORT"]}/0"
        CACHE_REDIS_URL                = "${var.helm_values["REDIS_HOST"]}:${var.helm_values["REDIS_PORT"]}/0"
        SYSTEM_REDIS_URL               = "${var.helm_values["REDIS_HOST"]}:${var.helm_values["REDIS_PORT"]}/0"
        QUEUE_REDIS_URL                = "${var.helm_values["REDIS_HOST"]}:${var.helm_values["REDIS_PORT"]}/0"
        WORKFLOW_REDIS_URL             = "${var.helm_values["REDIS_HOST"]}:${var.helm_values["REDIS_PORT"]}/0"
        CACHE_REDIS_CLUSTER_ENABLED    = "false"
        SYSTEM_REDIS_CLUSTER_ENABLED   = "false"
        QUEUE_REDIS_CLUSTER_ENABLED    = "false"
        WORKFLOW_REDIS_CLUSTER_ENABLED = "false"

        MINIO_BROWSER        = "off"
        MINIO_NGINX_PROXY    = "on"
        MINIO_MODE           = "gateway-s3"
        MINIO_INSTANCE_COUNT = "1"
        MINIO_REGION         = var.aws_region

        CERBERUS_PORT  = local.microservices.cerberus.port
        CONNECT_PORT   = local.microservices.connect.port
        DASHBOARD_PORT = local.microservices.dashboard.port
        HERCULES_PORT  = local.microservices.hercules.port
        HERMES_PORT    = local.microservices.hermes.port
        MINIO_PORT     = local.microservices.minio.port
        PASSPORT_PORT  = local.microservices.passport.port
        ZEUS_PORT      = local.microservices.zeus.port

        CERBERUS_PRIVATE_URL  = "http://cerberus:${local.microservices.cerberus.port}"
        CONNECT_PRIVATE_URL   = "http://connect:${local.microservices.connect.port}"
        DASHBOARD_PRIVATE_URL = "http://dashboard:${local.microservices.dashboard.port}"
        HERCULES_PRIVATE_URL  = "http://hercules:${local.microservices.hercules.port}"
        HERMES_PRIVATE_URL    = "http://hermes:${local.microservices.hermes.port}"
        MINIO_PRIVATE_URL     = "http://minio:${local.microservices.minio.port}"
        PASSPORT_PRIVATE_URL  = "http://passport:${local.microservices.passport.port}"
        ZEUS_PRIVATE_URL      = "http://zeus:${local.microservices.zeus.port}"
    }) : key => value if !contains(local.helm_keys_to_remove, key)
  }
}
