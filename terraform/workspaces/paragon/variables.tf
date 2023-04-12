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

variable "monitors_enabled" {
  description = "Specifies that monitors are enabled."
  type        = bool
  default     = false
}

variable "monitor_version" {
  description = "The version of the monitors to install."
  type        = string
  default     = "1.0.0"
}

variable "helm_values" {
  description = "Object containing values values to pass to the helm chart."
  type = object({
    subchart = map(object({
      enabled = bool
    }))
    global = object({
      env = map(string)
    })
  })
}

locals {
  _microservices = {
    "cerberus" = {
      "port"             = lookup(var.helm_values.global.env, "CERBERUS_PORT", 1700)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "CERBERUS_PUBLIC_URL", "https://cerberus.${var.domain}")
    }
    "chronos" = {
      "port"             = lookup(var.helm_values.global.env, "CHRONOS_PORT", 1708)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "CHRONOS_PUBLIC_URL", "https://chronos.${var.domain}")
    }
    "connect" = {
      "port"             = lookup(var.helm_values.global.env, "CONNECT_PORT", 1707)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "CONNECT_PUBLIC_URL", "https://connect.${var.domain}")
    }
    "dashboard" = {
      "port"             = lookup(var.helm_values.global.env, "DASHBOARD_PORT", 1704)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "DASHBOARD_PUBLIC_URL", "https://dashboard.${var.domain}")
    }
    "hades" = {
      "port"             = lookup(var.helm_values.global.env, "HADES_PORT", 1710)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "HADES_PUBLIC_URL", "https://hades.${var.domain}")
    }
    "hercules" = {
      "port"             = lookup(var.helm_values.global.env, "HERCULES_PORT", 1701)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "HERCULES_PUBLIC_URL", "https://hercules.${var.domain}")
    }
    "hermes" = {
      "port"             = lookup(var.helm_values.global.env, "HERMES_PORT", 1702)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "HERMES_PUBLIC_URL", "https://hermes.${var.domain}")
    }
    "minio" = {
      "port"             = lookup(var.helm_values.global.env, "MINIO_PORT", 9000)
      "healthcheck_path" = "/minio/health/live"
      "public_url"       = lookup(var.helm_values.global.env, "MINIO_PUBLIC_URL", "https://minio.${var.domain}")
    }
    "passport" = {
      "port"             = lookup(var.helm_values.global.env, "PASSPORT_PORT", 1706)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "PASSPORT_PUBLIC_URL", "https://passport.${var.domain}")
    }
    "pheme" = {
      "port"             = lookup(var.helm_values.global.env, "PHEME_PORT", 1709)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "PHEME_PUBLIC_URL", "https://pheme.${var.domain}")
    }
    "plato" = {
      "port"             = lookup(var.helm_values.global.env, "PLATO_PORT", 1711)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "PLATO_PUBLIC_URL", "https://plato.${var.domain}")
    }
    "zeus" = {
      "port"             = lookup(var.helm_values.global.env, "ZEUS_PORT", 1703)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(var.helm_values.global.env, "ZEUS_PUBLIC_URL", "https://zeus.${var.domain}")
    }
  }

  microservices_to_remove = [
    for microservice, config in var.helm_values.subchart : microservice
    if config.enabled == false
  ]

  microservices = {
    for microservice, config in local._microservices :
    microservice => config
    if !contains(local.microservices_to_remove, microservice)
  }

  monitors = {
    "beethoven-exporter" = {
      "port"       = 8002
      "public_url" = null
    }
    "bull-exporter" = {
      "port"       = 9538
      "public_url" = null
    }
    "grafana" = {
      "port"       = 4500
      "public_url" = lookup(var.helm_values.global.env, "MONITOR_GRAFANA_SERVER_DOMAIN", "https://grafana.${var.domain}")
    }
    "pgadmin" = {
      "port"       = 5050
      "public_url" = null
    }
    "prometheus" = {
      "port"       = 9090
      "public_url" = null
    }
    "postgres-exporter" = {
      "port"       = 9187
      "public_url" = null
    }
    "redis-exporter" = {
      "port"       = 9121
      "public_url" = null
    }
    "redis-insight" = {
      "port"       = 8500
      "public_url" = null
    }
  }

  public_monitors = var.monitors_enabled ? {
    for monitor, config in local.monitors :
    monitor => config
    if lookup(config, "public_url", null) != null
  } : {}

  helm_keys_to_remove = [
    "POSTGRES_HOST",
    "POSTGRES_PORT",
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_DATABASE",
    "REDIS_HOST",
    "REDIS_PORT",
  ]

  helm_values = merge(var.helm_values, {
    global = merge(var.helm_values.global, {
      env = merge(var.helm_values.global.env, {
        for key, value in merge({
          // default values, can be overridden by `.env-helm`
          NODE_ENV              = "production"
          PLATFORM_ENV          = "enterprise"
          BRANCH                = "master"
          SENDGRID_API_KEY      = "SG.xxx"
          SENDGRID_FROM_ADDRESS = "not-a-real@email.com"

          CERBERUS_PUBLIC_URL  = try(local.microservices.cerberus.public_url, null)
          CHRONOS_PUBLIC_URL   = try(local.microservices.chronos.public_url, null)
          CONNECT_PUBLIC_URL   = try(local.microservices.connect.public_url, null)
          DASHBOARD_PUBLIC_URL = try(local.microservices.dashboard.public_url, null)
          HADES_PUBLIC_URL     = try(local.microservices.hades.public_url, null)
          HERCULES_PUBLIC_URL  = try(local.microservices.hercules.public_url, null)
          HERMES_PUBLIC_URL    = try(local.microservices.hermes.public_url, null)
          MINIO_PUBLIC_URL     = try(local.microservices.minio.public_url, null)
          PASSPORT_PUBLIC_URL  = try(local.microservices.passport.public_url, null)
          PHEME_PUBLIC_URL     = try(local.microservices.pheme.public_url, null)
          PLATO_PUBLIC_URL     = try(local.microservices.plato.public_url, null)
          ZEUS_PUBLIC_URL      = try(local.microservices.zeus.public_url, null)

          MONITOR_GRAFANA_SLACK_CANARY_CHANNEL          = "<PLACEHOLDER>"
          MONITOR_GRAFANA_SLACK_CANARY_BETA_CHANNEL     = "<PLACEHOLDER>"
          MONITOR_GRAFANA_SLACK_CANARY_WEBHOOK_URL      = "<PLACEHOLDER>"
          MONITOR_GRAFANA_SLACK_CANARY_BETA_WEBHOOK_URL = "<PLACEHOLDER>"
          },
          // custom values provided in `.env-helm`, overrides default values
          var.helm_values.global.env,
          {
            // transformations, take priority over `.env-helm`
            AWS_REGION   = var.aws_region
            REGION       = var.aws_region
            ORGANIZATION = var.organization
            HOST_ENV     = "AWS_K8"

            // worker variables
            HERCULES_CLUSTER_MAX_INSTANCES = 1
            HERCULES_CLUSTER_DISABLED      = true

            ADMIN_BASIC_AUTH_USERNAME = var.helm_values.global.env["LICENSE"]
            ADMIN_BASIC_AUTH_PASSWORD = var.helm_values.global.env["LICENSE"]

            BEETHOVEN_POSTGRES_HOST     = var.helm_values.global.env["POSTGRES_HOST"]
            BEETHOVEN_POSTGRES_PORT     = var.helm_values.global.env["POSTGRES_PORT"]
            BEETHOVEN_POSTGRES_USERNAME = var.helm_values.global.env["POSTGRES_USER"]
            BEETHOVEN_POSTGRES_PASSWORD = var.helm_values.global.env["POSTGRES_PASSWORD"]
            BEETHOVEN_POSTGRES_DATABASE = var.helm_values.global.env["POSTGRES_DATABASE"]
            CERBERUS_POSTGRES_HOST      = var.helm_values.global.env["POSTGRES_HOST"]
            CERBERUS_POSTGRES_PORT      = var.helm_values.global.env["POSTGRES_PORT"]
            CERBERUS_POSTGRES_USERNAME  = var.helm_values.global.env["POSTGRES_USER"]
            CERBERUS_POSTGRES_PASSWORD  = var.helm_values.global.env["POSTGRES_PASSWORD"]
            CERBERUS_POSTGRES_DATABASE  = var.helm_values.global.env["POSTGRES_DATABASE"]
            HERMES_POSTGRES_HOST        = var.helm_values.global.env["POSTGRES_HOST"]
            HERMES_POSTGRES_PORT        = var.helm_values.global.env["POSTGRES_PORT"]
            HERMES_POSTGRES_USERNAME    = var.helm_values.global.env["POSTGRES_USER"]
            HERMES_POSTGRES_PASSWORD    = var.helm_values.global.env["POSTGRES_PASSWORD"]
            HERMES_POSTGRES_DATABASE    = var.helm_values.global.env["POSTGRES_DATABASE"]
            PHEME_POSTGRES_HOST         = var.helm_values.global.env["POSTGRES_HOST"]
            PHEME_POSTGRES_PORT         = var.helm_values.global.env["POSTGRES_PORT"]
            PHEME_POSTGRES_USERNAME     = var.helm_values.global.env["POSTGRES_USER"]
            PHEME_POSTGRES_PASSWORD     = var.helm_values.global.env["POSTGRES_PASSWORD"]
            PHEME_POSTGRES_DATABASE     = var.helm_values.global.env["POSTGRES_DATABASE"]
            ZEUS_POSTGRES_HOST          = var.helm_values.global.env["POSTGRES_HOST"]
            ZEUS_POSTGRES_PORT          = var.helm_values.global.env["POSTGRES_PORT"]
            ZEUS_POSTGRES_USERNAME      = var.helm_values.global.env["POSTGRES_USER"]
            ZEUS_POSTGRES_PASSWORD      = var.helm_values.global.env["POSTGRES_PASSWORD"]
            ZEUS_POSTGRES_DATABASE      = var.helm_values.global.env["POSTGRES_DATABASE"]

            REDIS_URL                      = "${var.helm_values.global.env["REDIS_HOST"]}:${var.helm_values.global.env["REDIS_PORT"]}/0"
            CACHE_REDIS_URL                = "${var.helm_values.global.env["REDIS_HOST"]}:${var.helm_values.global.env["REDIS_PORT"]}/0"
            SYSTEM_REDIS_URL               = "${var.helm_values.global.env["REDIS_HOST"]}:${var.helm_values.global.env["REDIS_PORT"]}/0"
            QUEUE_REDIS_URL                = "${var.helm_values.global.env["REDIS_HOST"]}:${var.helm_values.global.env["REDIS_PORT"]}/0"
            WORKFLOW_REDIS_URL             = "${var.helm_values.global.env["REDIS_HOST"]}:${var.helm_values.global.env["REDIS_PORT"]}/0"
            CACHE_REDIS_CLUSTER_ENABLED    = "false"
            SYSTEM_REDIS_CLUSTER_ENABLED   = "false"
            QUEUE_REDIS_CLUSTER_ENABLED    = "false"
            WORKFLOW_REDIS_CLUSTER_ENABLED = "false"

            MINIO_BROWSER        = "off"
            MINIO_NGINX_PROXY    = "on"
            MINIO_MODE           = "gateway-s3"
            MINIO_INSTANCE_COUNT = "1"
            MINIO_REGION         = var.aws_region

            CERBERUS_PORT  = try(local.microservices.cerberus.port, null)
            CHRONOS_PORT   = try(local.microservices.chronos.port, null)
            CONNECT_PORT   = try(local.microservices.connect.port, null)
            DASHBOARD_PORT = try(local.microservices.dashboard.port, null)
            HADES_PORT     = try(local.microservices.hades.port, null)
            HERCULES_PORT  = try(local.microservices.hercules.port, null)
            HERMES_PORT    = try(local.microservices.hermes.port, null)
            MINIO_PORT     = try(local.microservices.minio.port, null)
            PASSPORT_PORT  = try(local.microservices.passport.port, null)
            PHEME_PORT     = try(local.microservices.pheme.port, null)
            PLATO_PORT     = try(local.microservices.plato.port, null)
            ZEUS_PORT      = try(local.microservices.zeus.port, null)

            CERBERUS_PRIVATE_URL  = try("http://cerberus:${local.microservices.cerberus.port}", null)
            CHRONOS_PRIVATE_URL   = try("http://chronos:${local.microservices.chronos.port}", null)
            CONNECT_PRIVATE_URL   = try("http://connect:${local.microservices.connect.port}", null)
            DASHBOARD_PRIVATE_URL = try("http://dashboard:${local.microservices.dashboard.port}", null)
            HADES_PRIVATE_URL     = try("http://hades:${local.microservices.hades.port}", null)
            HERCULES_PRIVATE_URL  = try("http://hercules:${local.microservices.hercules.port}", null)
            HERMES_PRIVATE_URL    = try("http://hermes:${local.microservices.hermes.port}", null)
            MINIO_PRIVATE_URL     = try("http://minio:${local.microservices.minio.port}", null)
            PASSPORT_PRIVATE_URL  = try("http://passport:${local.microservices.passport.port}", null)
            PHEME_PRIVATE_URL     = try("http://pheme:${local.microservices.pheme.port}", null)
            PLATO_PRIVATE_URL     = try("http://plato:${local.microservices.plato.port}", null)
            ZEUS_PRIVATE_URL      = try("http://zeus:${local.microservices.zeus.port}", null)

            MONITOR_BEETHOVEN_EXPORTER_HOST         = "http://beethoven-exporter"
            MONITOR_BEETHOVEN_EXPORTER_PORT         = try(local.monitors["beethoven-exporter"].port, null)
            MONITOR_BULL_EXPORTER_HOST              = "http://bull-exporter"
            MONITOR_BULL_EXPORTER_PORT              = try(local.monitors["bull-exporter"].port, null)
            MONITOR_GRAFANA_AWS_ACCESS_ID           = var.monitors_enabled ? module.monitors[0].grafana_aws_access_key_id : null
            MONITOR_GRAFANA_AWS_SECRET_KEY          = var.monitors_enabled ? module.monitors[0].grafana_aws_secret_access_key : null
            MONITOR_GRAFANA_SERVER_DOMAIN           = try(local.monitors["grafana"].public_url, null)
            MONITOR_GRAFANA_SECURITY_ADMIN_USER     = var.monitors_enabled ? module.monitors[0].grafana_admin_email : null
            MONITOR_GRAFANA_SECURITY_ADMIN_PASSWORD = var.monitors_enabled ? module.monitors[0].grafana_admin_password : null
            MONITOR_GRAFANA_HOST                    = "http://grafana"
            MONITOR_GRAFANA_PORT                    = try(local.monitors["grafana"].port, null)
            MONITOR_PGADMIN_HOST                    = "http://pgadmin"
            MONITOR_PGADMIN_PORT                    = try(local.monitors["pgadmin"].port, null)
            MONITOR_PGADMIN_EMAIL                   = var.monitors_enabled ? module.monitors[0].pgadmin_admin_email : null
            MONITOR_PGADMIN_PASSWORD                = var.monitors_enabled ? module.monitors[0].pgadmin_admin_password : null
            MONITOR_PGADMIN_SSL_MODE                = "disable"
            MONITOR_QUEUE_REDIS_TARGET              = replace(element(split(".", var.helm_values.global.env.REDIS_HOST), 0), "redis://", "")
            MONITOR_POSTGRES_EXPORTER_HOST          = "http://postgres-exporter"
            MONITOR_POSTGRES_EXPORTER_PORT          = try(local.monitors["postgres-exporter"].port, null)
            MONITOR_POSTGRES_EXPORTER_SSL_MODE      = "disable"
            MONITOR_PROMETHEUS_HOST                 = "http://prometheus"
            MONITOR_PROMETHEUS_PORT                 = try(local.monitors["prometheus"].port, null)
            MONITOR_REDIS_EXPORTER_HOST             = "http://redis-exporter"
            MONITOR_REDIS_EXPORTER_PORT             = try(local.monitors["redis-exporter"].port, null)
            MONITOR_REDIS_INSIGHT_HOST              = "http://redis-insight"
            MONITOR_REDIS_INSIGHT_PORT              = try(local.monitors["redis-insight"].port, null)
        }) : key => value if !contains(local.helm_keys_to_remove, key) && value != null
      })
    })
  })
}
