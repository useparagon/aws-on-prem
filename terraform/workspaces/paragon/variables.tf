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
  default     = "enterprise"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN of an existing certificate to use with the load balancer."
  type        = string
  default     = null
}

variable "docker_registry_server" {
  description = "Docker container registry server."
  type        = string
  default     = "docker.io"
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
  description = "Docker email to pull images."
  type        = string
}

variable "logs_bucket" {
  description = "Bucket to store system logs."
  type        = string
  default     = ""
}

variable "monitors_enabled" {
  description = "Specifies that monitors are enabled."
  type        = bool
  default     = false
}

variable "monitor_version" {
  description = "The version of the monitors to install."
  type        = string
  default     = null
}

variable "monitor_grafana_customer_webhook_url" {
  description = "The webhook URL for customer notifications in Grafana."
  type        = string
  default     = null
}

variable "monitor_grafana_customer_defined_alerts_webhook_url" {
  description = "The webhook URL for customer-defined alerts in Grafana."
  type        = string
  default     = null
}

variable "supported_microservices" {
  description = "The microservices supported in the current Paragon version."
  type        = list(string)
}

variable "helm_values" {
  description = "Custom `values.yaml` file."
  type        = string
}

variable "helm_env" {
  description = "Enviroment variables to pass to helm from `.env-helm`."
  type        = string
}

variable "feature_flags" {
  description = "Optional base64 encoded feature flags YAML content."
  type        = string
  default     = null
}

variable "ingress_scheme" {
  description = "Whether the load balancer is 'internet-facing' (public) or 'internal' (private)"
  type        = string
  default     = "internet-facing"
}

variable "k8_version" {
  description = "The version of Kubernetes to run in the cluster."
  type        = string
  default     = "1.25"
}

variable "dns_provider" {
  description = "DNS provider to use."
  type        = string
  default     = "cloudflare"

  validation {
    condition     = var.dns_provider == "cloudflare" || var.dns_provider == "namecheap"
    error_message = "Only cloudflare and namecheap are currently supported."
  }
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

variable "uptime_api_token" {
  description = "Optional API Token for setting up BetterStack Uptime monitors."
  type        = string
  default     = null
}

variable "uptime_company" {
  description = "Optional pretty company name to include in BetterStack Uptime monitors."
  type        = string
  default     = null
}

variable "openobserve_email" {
  description = "OpenObserve admin login email."
  type        = string
  default     = null
}

variable "openobserve_password" {
  description = "OpenObserve admin login password."
  type        = string
  default     = null
}

variable "managed_sync_enabled" {
  description = "Whether to enable managed sync."
  type        = bool
  default     = false
}

variable "managed_sync_version" {
  description = "The version of the Managed Sync helm chart to install."
  type        = string
  default     = "latest"
}

locals {
  raw_helm_env = jsondecode(base64decode(var.helm_env))
  raw_helm_values = try(yamldecode(
    base64decode(var.helm_values),
  ), {})
  base_helm_values = merge(local.raw_helm_values, {
    global = merge(try(local.raw_helm_values.global, {}), {
      env = merge(try(local.raw_helm_values.global.env, {}), local.raw_helm_env)
    })
  })

  _microservices = {
    "account" = {
      "port"             = lookup(local.base_helm_values.global.env, "ACCOUNT_PORT", 1708)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "ACCOUNT_PUBLIC_URL", "https://account.${var.domain}")
    }
    "cache-replay" = {
      "port"             = lookup(local.base_helm_values.global.env, "CACHE_REPLAY_PORT", 1724)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "CACHE_REPLAY_PUBLIC_URL", "https://cache-replay.${var.domain}")
    }
    "cerberus" = {
      "port"             = lookup(local.base_helm_values.global.env, "CERBERUS_PORT", 1700)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "CERBERUS_PUBLIC_URL", "https://cerberus.${var.domain}")
    }
    "chronos" = {
      "port"             = lookup(local.base_helm_values.global.env, "CHRONOS_PORT", 1708)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "CHRONOS_PUBLIC_URL", "https://chronos.${var.domain}")
    }
    "connect" = {
      "port"             = lookup(local.base_helm_values.global.env, "CONNECT_PORT", 1707)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "CONNECT_PUBLIC_URL", "https://connect.${var.domain}")
    }
    "dashboard" = {
      "port"             = lookup(local.base_helm_values.global.env, "DASHBOARD_PORT", 1704)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "DASHBOARD_PUBLIC_URL", "https://dashboard.${var.domain}")
    }
    "flipt" = {
      "port"             = lookup(local.base_helm_values.global.env, "FLIPT_PORT", 1722)
      "healthcheck_path" = "/health"
      "public_url"       = lookup(local.base_helm_values.global.env, "FLIPT_PUBLIC_URL", null)
    }
    "hades" = {
      "port"             = lookup(local.base_helm_values.global.env, "HADES_PORT", 1710)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "HADES_PUBLIC_URL", "https://hades.${var.domain}")
    }
    "hercules" = {
      "port"             = lookup(local.base_helm_values.global.env, "HERCULES_PORT", 1701)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "HERCULES_PUBLIC_URL", "https://hercules.${var.domain}")
    }
    "hermes" = {
      "port"             = lookup(local.base_helm_values.global.env, "HERMES_PORT", 1702)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "HERMES_PUBLIC_URL", "https://hermes.${var.domain}")
    }
    "minio" = {
      "port"             = lookup(local.base_helm_values.global.env, "MINIO_PORT", 9000)
      "healthcheck_path" = "/minio/health/live"
      "public_url"       = lookup(local.base_helm_values.global.env, "MINIO_PUBLIC_URL", "https://minio.${var.domain}")
    }
    "passport" = {
      "port"             = lookup(local.base_helm_values.global.env, "PASSPORT_PORT", 1706)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "PASSPORT_PUBLIC_URL", "https://passport.${var.domain}")
    }
    "pheme" = {
      "port"             = lookup(local.base_helm_values.global.env, "PHEME_PORT", 1709)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "PHEME_PUBLIC_URL", "https://pheme.${var.domain}")
    }
    "plato" = {
      "port"             = lookup(local.base_helm_values.global.env, "PLATO_PORT", 1711)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "PLATO_PUBLIC_URL", "https://plato.${var.domain}")
    }
    "release" = {
      "port"             = lookup(local.base_helm_values.global.env, "RELEASE_PORT", 1719)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "RELEASE_PUBLIC_URL", "https://release.${var.domain}")
    }
    "zeus" = {
      "port"             = lookup(local.base_helm_values.global.env, "ZEUS_PORT", 1703)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "ZEUS_PUBLIC_URL", "https://zeus.${var.domain}")
    }
    "worker-actionkit" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_ACTIONKIT_PORT", 1721)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_ACTIONKIT_PUBLIC_URL", "https://worker-actionkit.${var.domain}")
    }
    "worker-actions" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_ACTIONS_PORT", 1712)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_ACTIONS_PUBLIC_URL", "https://worker-actions.${var.domain}")
    }
    "worker-credentials" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_CREDENTIALS_PORT", 1713)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_CREDENTIALS_PUBLIC_URL", "https://worker-credentials.${var.domain}")
    }
    "worker-crons" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_CRONS_PORT", 1714)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_CRONS_PUBLIC_URL", "https://worker-crons.${var.domain}")
    }
    "worker-deployments" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_DEPLOYMENTS_PORT", 1718)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_DEPLOYMENTS_PUBLIC_URL", "https://worker-deployments.${var.domain}")
    }
    "worker-proxy" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_PROXY_PORT", 1715)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_PROXY_PUBLIC_URL", "https://worker-proxy.${var.domain}")
    }
    "worker-triggers" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_TRIGGERS_PORT", 1716)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_TRIGGERS_PUBLIC_URL", "https://worker-triggers.${var.domain}")
    }
    "worker-workflows" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_WORKFLOWS_PORT", 1717)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_WORKFLOWS_PUBLIC_URL", "https://worker-workflows.${var.domain}")
    }
    "worker-eventlogs" = {
      "port"             = lookup(local.base_helm_values.global.env, "WORKER_EVENT_LOGS_PORT", 1723)
      "healthcheck_path" = "/healthz"
      "public_url"       = lookup(local.base_helm_values.global.env, "WORKER_EVENT_LOGS_PUBLIC_URL", "https://worker-eventlogs.${var.domain}")
    }
  }

  managed_sync_microservices = {
    "api-sync" = {
      "healthcheck_path" = "/healthz"
      "port"             = try(local.base_helm_values.global.env["API_SYNC_HTTP_PORT"], 1800)
      "public_url"       = try(local.base_helm_values.global.env["API_SYNC_PUBLIC_URL"], "https://ms-sync.${var.domain}")
    }
    "worker-sync" = {
      "healthcheck_path" = "/healthz"
      "port"             = try(local.base_helm_values.global.env["WORKER_SYNC_HTTP_PORT"], 1802)
      "public_url"       = try(local.base_helm_values.global.env["WORKER_SYNC_PUBLIC_URL"], "https://ms-worker-sync.${var.domain}")
    }
  }

  microservices = merge({
    for microservice, config in local._microservices :
    microservice => config
    if contains(var.supported_microservices, microservice)
  }, var.managed_sync_enabled ? local.managed_sync_microservices : {})

  public_microservices = {
    for microservice, config in local.microservices :
    microservice => config
    if config.public_url != null && config.public_url != ""
  }

  monitors = {
    "bull-exporter" = {
      "port"       = 9538
      "public_url" = null
    }
    "jaegar" = {
      "port"       = 4317
      "public_url" = null
    }
    "grafana" = {
      "port"       = 4500
      "public_url" = lookup(local.base_helm_values.global.env, "MONITOR_GRAFANA_SERVER_DOMAIN", "https://grafana.${var.domain}")
    }
    "kube-state-metrics" = {
      "port"       = 2550
      "public_url" = null
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

  helm_values = merge(local.base_helm_values, {
    global = merge(local.base_helm_values.global, {
      env = merge(local.base_helm_values.global.env, {
        for key, value in merge({
          // default values, can be overridden by `values.yaml -> global.env`
          NODE_ENV               = "production"
          PLATFORM_ENV           = "enterprise"
          BRANCH                 = "master"
          EMAIL_DELIVERY_SERVICE = "none"

          CLOUD_STORAGE_TYPE          = try(local.base_helm_values.global.env["CLOUD_STORAGE_TYPE"], "MINIO")
          CLOUD_STORAGE_PUBLIC_BUCKET = coalesce(try(local.base_helm_values.global.env["CLOUD_STORAGE_PUBLIC_BUCKET"], null), try(local.base_helm_values.global.env["MINIO_PUBLIC_BUCKET"], null), null)
          CLOUD_STORAGE_SYSTEM_BUCKET = coalesce(try(local.base_helm_values.global.env["CLOUD_STORAGE_SYSTEM_BUCKET"], null), try(local.base_helm_values.global.env["MINIO_SYSTEM_BUCKET"], null), null)

          ACCOUNT_PUBLIC_URL       = try(local.microservices.account.public_url, null)
          CERBERUS_PUBLIC_URL      = try(local.microservices.cerberus.public_url, null)
          CHRONOS_PUBLIC_URL       = try(local.microservices.chronos.public_url, null)
          CLOUD_STORAGE_PUBLIC_URL = coalesce(try(local.base_helm_values.global.env["CLOUD_STORAGE_PUBLIC_URL"], null), try(local.base_helm_values.global.env["MINIO_PUBLIC_URL"], null), "https://s3.${var.aws_region}.amazonaws.com")
          CONNECT_PUBLIC_URL       = try(local.microservices.connect.public_url, null)
          DASHBOARD_PUBLIC_URL     = try(local.microservices.dashboard.public_url, null)
          HADES_PUBLIC_URL         = try(local.microservices.hades.public_url, null)
          HERCULES_PUBLIC_URL      = try(local.microservices.hercules.public_url, null)
          HERMES_PUBLIC_URL        = try(local.microservices.hermes.public_url, null)
          MINIO_PUBLIC_URL         = try(local.microservices.minio.public_url, null)
          PASSPORT_PUBLIC_URL      = try(local.microservices.passport.public_url, null)
          PHEME_PUBLIC_URL         = try(local.microservices.pheme.public_url, null)
          PLATO_PUBLIC_URL         = try(local.microservices.plato.public_url, null)
          ZEUS_PUBLIC_URL          = try(local.microservices.zeus.public_url, null)

          WORKER_ACTIONKIT_PUBLIC_URL   = try(local.microservices["worker-actionkit"].public_url, null)
          WORKER_ACTIONS_PUBLIC_URL     = try(local.microservices["worker-actions"].public_url, null)
          WORKER_CREDENTIALS_PUBLIC_URL = try(local.microservices["worker-credentials"].public_url, null)
          WORKER_CRONS_PUBLIC_URL       = try(local.microservices["worker-crons"].public_url, null)
          WORKER_DEPLOYMENTS_PUBLIC_URL = try(local.microservices["worker-deployments"].public_url, null)
          WORKER_PROXY_PUBLIC_URL       = try(local.microservices["worker-proxy"].public_url, null)
          WORKER_TRIGGERS_PUBLIC_URL    = try(local.microservices["worker-triggers"].public_url, null)
          WORKER_WORKFLOWS_PUBLIC_URL   = try(local.microservices["worker-workflows"].public_url, null)
          WORKER_EVENT_LOGS_PUBLIC_URL   = try(local.microservices["worker-eventlogs"].public_url, null)

          MICROSERVICES_OPENTELEMETRY_ENABLED = false
          },
          // custom values provided in `values.yaml`, overrides default values
          local.base_helm_values.global.env,
          {
            // transformations, take priority over `values.yaml` -> global.env
            AWS_REGION     = var.aws_region
            REGION         = var.aws_region
            ORGANIZATION   = var.organization
            PARAGON_DOMAIN = var.domain
            HOST_ENV       = "AWS_K8"

            // worker variables
            WORKER_WORKFLOWS_MINIMUM_HERMES_PROCESSOR_QUEUE_COUNT = 0
            WORKER_WORKFLOWS_MINIMUM_TEST_WORKFLOW_QUEUE_COUNT    = 1

            ADMIN_BASIC_AUTH_USERNAME = local.base_helm_values.global.env["LICENSE"]
            ADMIN_BASIC_AUTH_PASSWORD = local.base_helm_values.global.env["LICENSE"]

            BEETHOVEN_POSTGRES_HOST     = try(local.base_helm_values.global.env["BEETHOVEN_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
            BEETHOVEN_POSTGRES_PORT     = try(local.base_helm_values.global.env["BEETHOVEN_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            BEETHOVEN_POSTGRES_USERNAME = try(local.base_helm_values.global.env["BEETHOVEN_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            BEETHOVEN_POSTGRES_PASSWORD = try(local.base_helm_values.global.env["BEETHOVEN_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            BEETHOVEN_POSTGRES_DATABASE = try(local.base_helm_values.global.env["BEETHOVEN_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
            CERBERUS_POSTGRES_HOST      = try(local.base_helm_values.global.env["CERBERUS_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
            CERBERUS_POSTGRES_PORT      = try(local.base_helm_values.global.env["CERBERUS_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            CERBERUS_POSTGRES_USERNAME  = try(local.base_helm_values.global.env["CERBERUS_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            CERBERUS_POSTGRES_PASSWORD  = try(local.base_helm_values.global.env["CERBERUS_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            CERBERUS_POSTGRES_DATABASE  = try(local.base_helm_values.global.env["CERBERUS_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
            HERMES_POSTGRES_HOST        = try(local.base_helm_values.global.env["HERMES_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
            HERMES_POSTGRES_PORT        = try(local.base_helm_values.global.env["HERMES_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            HERMES_POSTGRES_USERNAME    = try(local.base_helm_values.global.env["HERMES_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            HERMES_POSTGRES_PASSWORD    = try(local.base_helm_values.global.env["HERMES_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            HERMES_POSTGRES_DATABASE    = try(local.base_helm_values.global.env["HERMES_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
            PHEME_POSTGRES_HOST         = try(local.base_helm_values.global.env["PHEME_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
            PHEME_POSTGRES_PORT         = try(local.base_helm_values.global.env["PHEME_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            PHEME_POSTGRES_USERNAME     = try(local.base_helm_values.global.env["PHEME_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            PHEME_POSTGRES_PASSWORD     = try(local.base_helm_values.global.env["PHEME_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            PHEME_POSTGRES_DATABASE     = try(local.base_helm_values.global.env["PHEME_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
            ZEUS_POSTGRES_HOST          = try(local.base_helm_values.global.env["ZEUS_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
            ZEUS_POSTGRES_PORT          = try(local.base_helm_values.global.env["ZEUS_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            ZEUS_POSTGRES_USERNAME      = try(local.base_helm_values.global.env["ZEUS_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            ZEUS_POSTGRES_PASSWORD      = try(local.base_helm_values.global.env["ZEUS_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            ZEUS_POSTGRES_DATABASE      = try(local.base_helm_values.global.env["ZEUS_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
            EVENT_LOGS_POSTGRES_PORT          = try(local.base_helm_values.global.env["EVENT_LOGS_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
            EVENT_LOGS_POSTGRES_USERNAME      = try(local.base_helm_values.global.env["EVENT_LOGS_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
            EVENT_LOGS_POSTGRES_PASSWORD      = try(local.base_helm_values.global.env["EVENT_LOGS_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
            EVENT_LOGS_POSTGRES_DATABASE      = try(local.base_helm_values.global.env["ZEUS_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])

            REDIS_URL = try(
              local.base_helm_values.global.env["REDIS_URL"],
              try("${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0", null),
            )
            CACHE_REDIS_URL                = try(local.base_helm_values.global.env["CACHE_REDIS_URL"], "${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0")
            SYSTEM_REDIS_URL               = try(local.base_helm_values.global.env["SYSTEM_REDIS_URL"], "${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0")
            QUEUE_REDIS_URL                = try(local.base_helm_values.global.env["QUEUE_REDIS_URL"], "${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0")
            WORKFLOW_REDIS_URL             = try(local.base_helm_values.global.env["WORKFLOW_REDIS_URL"], "${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0")
            CACHE_REDIS_CLUSTER_ENABLED    = try(local.base_helm_values.global.env["CACHE_REDIS_CLUSTER_ENABLED"], "false")
            SYSTEM_REDIS_CLUSTER_ENABLED   = try(local.base_helm_values.global.env["SYSTEM_REDIS_CLUSTER_ENABLED"], "false")
            QUEUE_REDIS_CLUSTER_ENABLED    = try(local.base_helm_values.global.env["QUEUE_REDIS_CLUSTER_ENABLED"], "false")
            WORKFLOW_REDIS_CLUSTER_ENABLED = try(local.base_helm_values.global.env["WORKFLOW_REDIS_CLUSTER_ENABLED"], "false")

            MINIO_BROWSER        = "off"
            MINIO_NGINX_PROXY    = "on"
            MINIO_MODE           = "gateway-s3"
            MINIO_INSTANCE_COUNT = "1"
            MINIO_REGION         = var.aws_region

            ACCOUNT_PORT      = try(local.microservices.account.port, null)
            CACHE_REPLAY_PORT = try(local.microservices["cache-replay"].port, null)
            CERBERUS_PORT     = try(local.microservices.cerberus.port, null)
            CHRONOS_PORT      = try(local.microservices.chronos.port, null)
            CONNECT_PORT      = try(local.microservices.connect.port, null)
            DASHBOARD_PORT    = try(local.microservices.dashboard.port, null)
            HADES_PORT        = try(local.microservices.hades.port, null)
            HERCULES_PORT     = try(local.microservices.hercules.port, null)
            HERMES_PORT       = try(local.microservices.hermes.port, null)
            MINIO_PORT        = try(local.microservices.minio.port, null)
            PASSPORT_PORT     = try(local.microservices.passport.port, null)
            PHEME_PORT        = try(local.microservices.pheme.port, null)
            PLATO_PORT        = try(local.microservices.plato.port, null)
            RELEASE_PORT      = try(local.microservices.release.port, null)
            ZEUS_PORT         = try(local.microservices.zeus.port, null)

            WORKER_ACTIONKIT_PORT   = try(local.microservices["worker-actionkit"].port, null)
            WORKER_ACTIONS_PORT     = try(local.microservices["worker-actions"].port, null)
            WORKER_CREDENTIALS_PORT = try(local.microservices["worker-credentials"].port, null)
            WORKER_CRONS_PORT       = try(local.microservices["worker-crons"].port, null)
            WORKER_DEPLOYMENTS_PORT = try(local.microservices["worker-deployments"].port, null)
            WORKER_PROXY_PORT       = try(local.microservices["worker-proxy"].port, null)
            WORKER_TRIGGERS_PORT    = try(local.microservices["worker-triggers"].port, null)
            WORKER_WORKFLOWS_PORT   = try(local.microservices["worker-workflows"].port, null)
            WORKER_EVENT_LOGS_PORT   = try(local.microservices["worker-eventlogs"].port, null)

            ACCOUNT_PRIVATE_URL       = try("http://account:${local.microservices.account.port}", null)
            CACHE_REPLAY_PRIVATE_URL  = try("http://cache-replay:${local.microservices["cache-replay"].port}", null)
            CERBERUS_PRIVATE_URL      = try("http://cerberus:${local.microservices.cerberus.port}", null)
            CHRONOS_PRIVATE_URL       = try("http://chronos:${local.microservices.chronos.port}", null)
            CLOUD_STORAGE_PRIVATE_URL = try("http://minio:${local.microservices.minio.port}", null)
            CONNECT_PRIVATE_URL       = try("http://connect:${local.microservices.connect.port}", null)
            DASHBOARD_PRIVATE_URL     = try("http://dashboard:${local.microservices.dashboard.port}", null)
            EMBASSY_PRIVATE_URL       = "http://embassy:1705"
            HADES_PRIVATE_URL         = try("http://hades:${local.microservices.hades.port}", null)
            HERCULES_PRIVATE_URL      = try("http://hercules:${local.microservices.hercules.port}", null)
            HERMES_PRIVATE_URL        = try("http://hermes:${local.microservices.hermes.port}", null)
            MINIO_PRIVATE_URL         = try("http://minio:${local.microservices.minio.port}", null)
            PASSPORT_PRIVATE_URL      = try("http://passport:${local.microservices.passport.port}", null)
            PHEME_PRIVATE_URL         = try("http://pheme:${local.microservices.pheme.port}", null)
            PLATO_PRIVATE_URL         = try("http://plato:${local.microservices.plato.port}", null)
            RELEASE_PRIVATE_URL       = try("http://release:${local.microservices.release.port}", null)
            ZEUS_PRIVATE_URL          = try("http://zeus:${local.microservices.zeus.port}", null)

            WORKER_ACTIONKIT_PRIVATE_URL   = try("http://worker-actionkit:${local.microservices["worker-actionkit"].port}", null)
            WORKER_ACTIONS_PRIVATE_URL     = try("http://worker-actions:${local.microservices["worker-actions"].port}", null)
            WORKER_CREDENTIALS_PRIVATE_URL = try("http://worker-credentials:${local.microservices["worker-credentials"].port}", null)
            WORKER_CRONS_PRIVATE_URL       = try("http://worker-crons:${local.microservices["worker-crons"].port}", null)
            WORKER_DEPLOYMENTS_PRIVATE_URL = try("http://worker-deployments:${local.microservices["worker-deployments"].port}", null)
            WORKER_PROXY_PRIVATE_URL       = try("http://worker-proxy:${local.microservices["worker-proxy"].port}", null)
            WORKER_TRIGGERS_PRIVATE_URL    = try("http://worker-triggers:${local.microservices["worker-triggers"].port}", null)
            WORKER_WORKFLOWS_PRIVATE_URL   = try("http://worker-workflows:${local.microservices["worker-workflows"].port}", null)
            WORKER_EVENT_LOGS_PRIVATE_URL   = try("http://worker-eventlogs:${local.microservices["worker-eventlogs"].port}", null)

            FEATURE_FLAG_PLATFORM_ENABLED  = "true"
            FEATURE_FLAG_PLATFORM_ENDPOINT = "http://flipt:${local.microservices.flipt.port}"

            MONITOR_BULL_EXPORTER_HOST                          = "http://bull-exporter"
            MONITOR_BULL_EXPORTER_PORT                          = try(local.monitors["bull-exporter"].port, null)
            MONITOR_GRAFANA_AWS_ACCESS_ID                       = var.monitors_enabled ? module.monitors[0].grafana_aws_access_key_id : null
            MONITOR_GRAFANA_AWS_SECRET_KEY                      = var.monitors_enabled ? module.monitors[0].grafana_aws_secret_access_key : null
            MONITOR_GRAFANA_SERVER_DOMAIN                       = try(local.monitors["grafana"].public_url, null)
            MONITOR_GRAFANA_SECURITY_ADMIN_USER                 = var.monitors_enabled ? module.monitors[0].grafana_admin_email : null
            MONITOR_GRAFANA_SECURITY_ADMIN_PASSWORD             = var.monitors_enabled ? module.monitors[0].grafana_admin_password : null
            MONITOR_GRAFANA_HOST                                = "http://grafana"
            MONITOR_GRAFANA_PORT                                = try(local.monitors["grafana"].port, null)
            MONITOR_GRAFANA_UPTIME_WEBHOOK_URL                  = module.uptime.webhook
            MONITOR_GRAFANA_CUSTOMER_WEBHOOK_URL                = var.monitor_grafana_customer_webhook_url
            MONITOR_GRAFANA_CUSTOMER_DEFINED_ALERTS_WEBHOOK_URL = var.monitor_grafana_customer_defined_alerts_webhook_url
            MONITOR_JAEGER_COLLECTOR_OTLP_GRPC_HOST             = "http://jaegar"
            MONITOR_JAEGER_COLLECTOR_OTLP_GRPC_PORT             = try(local.monitors["jaegar"].port, null)
            MONITOR_KUBE_STATE_METRICS_HOST                     = "http://kube-state-metrics"
            MONITOR_KUBE_STATE_METRICS_PORT                     = try(local.monitors["kube-state-metrics"].port, null)
            MONITOR_PGADMIN_HOST                                = "http://pgadmin"
            MONITOR_PGADMIN_PORT                                = try(local.monitors["pgadmin"].port, null)
            MONITOR_PGADMIN_EMAIL                               = var.monitors_enabled ? module.monitors[0].pgadmin_admin_email : null
            MONITOR_PGADMIN_PASSWORD                            = var.monitors_enabled ? module.monitors[0].pgadmin_admin_password : null
            MONITOR_PGADMIN_SSL_MODE                            = "disable"
            MONITOR_QUEUE_REDIS_TARGET = replace(element(split(".", try(
              local.base_helm_values.global.env["REDIS_HOST"],
              local.base_helm_values.global.env["QUEUE_REDIS_URL"]
            )), 0), "redis://", "")
            MONITOR_POSTGRES_EXPORTER_HOST     = "http://postgres-exporter"
            MONITOR_POSTGRES_EXPORTER_PORT     = try(local.monitors["postgres-exporter"].port, null)
            MONITOR_POSTGRES_EXPORTER_SSL_MODE = "disable"
            MONITOR_PROMETHEUS_HOST            = "http://prometheus"
            MONITOR_PROMETHEUS_PORT            = try(local.monitors["prometheus"].port, null)
            MONITOR_REDIS_EXPORTER_HOST        = "http://redis-exporter"
            MONITOR_REDIS_EXPORTER_PORT        = try(local.monitors["redis-exporter"].port, null)
            MONITOR_REDIS_INSIGHT_HOST         = "http://redis-insight"
            MONITOR_REDIS_INSIGHT_PORT         = try(local.monitors["redis-insight"].port, null)
        }) : key => value if !contains(local.helm_keys_to_remove, key) && value != null
        }, var.managed_sync_enabled ? {
        API_SYNC_HTTP_PORT    = try(local.managed_sync_microservices["api-sync"].port, null)
        WORKER_SYNC_HTTP_PORT = try(local.managed_sync_microservices["worker-sync"].port, null)

        CLOUD_STORAGE_MANAGED_SYNC_BUCKET = try(local.base_helm_values.global.env["MINIO_MANAGED_SYNC_BUCKET"], null)
        CLOUD_STORAGE_PASS                = try(local.base_helm_values.global.env["MINIO_MICROSERVICE_PASS"], null)
        CLOUD_STORAGE_USER                = try(local.base_helm_values.global.env["MINIO_MICROSERVICE_USER"], null)

        MANAGED_SYNC_KAFKA_BROKER_URLS                       = try(local.base_helm_values.global.env["MANAGED_SYNC_KAFKA_BROKER_URLS"], null)
        MANAGED_SYNC_KAFKA_SASL_USERNAME                     = try(local.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_USERNAME"], null)
        MANAGED_SYNC_KAFKA_SASL_PASSWORD                     = try(local.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_PASSWORD"], null)
        MANAGED_SYNC_KAFKA_SASL_MECHANISM                    = try(local.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_MECHANISM"], null)
        MANAGED_SYNC_KAFKA_SSL_ENABLED                       = try(local.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SSL_ENABLED"], null)
        MANAGED_SYNC_KAFKA_TOPICS_DEFAULT_REPLICATION_FACTOR = 1

        MANAGED_SYNC_REDIS_URL             = try(local.base_helm_values.global.env["MANAGED_SYNC_REDIS_URL"], "${local.base_helm_values.global.env["REDIS_HOST"]}:${local.base_helm_values.global.env["REDIS_PORT"]}/0")
        MANAGED_SYNC_REDIS_CLUSTER_ENABLED = try(local.base_helm_values.global.env["MANAGED_SYNC_REDIS_CLUSTER_ENABLED"], "false")
        MANAGED_SYNC_REDIS_TLS_ENABLED     = try(local.base_helm_values.global.env["MANAGED_SYNC_REDIS_TLS_ENABLED"], "false")

        OPENFGA_POSTGRES_HOST        = try(local.base_helm_values.global.env["OPENFGA_POSTGRES_HOST"], local.base_helm_values.global.env["POSTGRES_HOST"])
        OPENFGA_POSTGRES_PORT        = try(local.base_helm_values.global.env["OPENFGA_POSTGRES_PORT"], local.base_helm_values.global.env["POSTGRES_PORT"])
        OPENFGA_POSTGRES_USERNAME    = try(local.base_helm_values.global.env["OPENFGA_POSTGRES_USERNAME"], local.base_helm_values.global.env["POSTGRES_USER"])
        OPENFGA_POSTGRES_PASSWORD    = try(local.base_helm_values.global.env["OPENFGA_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"])
        OPENFGA_POSTGRES_DATABASE    = try(local.base_helm_values.global.env["OPENFGA_POSTGRES_DATABASE"], local.base_helm_values.global.env["POSTGRES_DATABASE"])
        OPENFGA_POSTGRES_SSL_ENABLED = true

        OPENFGA_HTTP_PORT           = 6200
        OPENFGA_GRPC_PORT           = 6201
        OPENFGA_AUTH_METHOD         = "preshared",
        OPENFGA_AUTH_PRESHARED_KEYS = sha256(try(local.base_helm_values.global.env["OPENFGA_POSTGRES_PASSWORD"], local.base_helm_values.global.env["POSTGRES_PASSWORD"]))
        OPENFGA_HTTP_URL            = "http://openfga:${6200}"

        PARAGON_PROXY_BASE_URL = try("http://worker-proxy:${local.microservices["worker-proxy"].port}", null)
      } : {})
    })
  })

  monitor_version = var.monitor_version != null ? var.monitor_version : try(local.helm_values.global.env["VERSION"], "latest")

  feature_flags_content = var.feature_flags != null ? base64decode(var.feature_flags) : null

  flipt_options = {
    for key, value in merge(
      # user overrides
      local.base_helm_values.global.env,
      {
        FLIPT_CACHE_ENABLED             = "true"
        FLIPT_LOG_GRPC_LEVEL            = "warn"
        FLIPT_LOG_LEVEL                 = "warn"
        FLIPT_STORAGE_GIT_POLL_INTERVAL = "30s"
        FLIPT_STORAGE_GIT_REF           = "main"
        FLIPT_STORAGE_GIT_REPOSITORY    = local.feature_flags_content != null ? null : "https://github.com/useparagon/feature-flags.git"
        FLIPT_STORAGE_LOCAL_PATH        = local.feature_flags_content != null ? "/var/opt/flipt" : null
        FLIPT_STORAGE_READ_ONLY         = "true"
        FLIPT_STORAGE_TYPE              = local.feature_flags_content != null ? "local" : "git"
    }) :
    key => value
    if key != null && key != "" && value != null && value != "" && can(regex("^FLIPT_", key))
  }
}
