locals {
  postgres_config = {
    admin = {
      # these are the default credentials for the admin postgres instance
      # if using multiple postgres instances, it should be set to the `managed-sync` instance
      host     = try(var.base_helm_values.global.env["ADMIN_POSTGRES_HOST"], var.base_helm_values.global.env["POSTGRES_HOST"])
      port     = try(var.base_helm_values.global.env["ADMIN_POSTGRES_PORT"], var.base_helm_values.global.env["POSTGRES_PORT"])
      username = try(var.base_helm_values.global.env["ADMIN_POSTGRES_USERNAME"], var.base_helm_values.global.env["POSTGRES_USER"])
      password = try(var.base_helm_values.global.env["ADMIN_POSTGRES_PASSWORD"], var.base_helm_values.global.env["POSTGRES_PASSWORD"])
      database = try(var.base_helm_values.global.env["ADMIN_POSTGRES_DATABASE"], var.base_helm_values.global.env["POSTGRES_DATABASE"])
    }
    openfga = {
      host     = try(var.base_helm_values.global.env["OPENFGA_POSTGRES_HOST"], var.base_helm_values.global.env["POSTGRES_HOST"])
      port     = try(var.base_helm_values.global.env["OPENFGA_POSTGRES_PORT"], var.base_helm_values.global.env["POSTGRES_PORT"])
      username = try(var.base_helm_values.global.env["OPENFGA_POSTGRES_USERNAME"], random_string.postgres_username["openfga"].result)
      password = try(var.base_helm_values.global.env["OPENFGA_POSTGRES_PASSWORD"], random_password.postgres_password["openfga"].result)
      database = "openfga"
    }
    sync_instance = {
      host     = try(var.base_helm_values.global.env["SYNC_INSTANCE_POSTGRES_HOST"], var.base_helm_values.global.env["POSTGRES_HOST"])
      port     = try(var.base_helm_values.global.env["SYNC_INSTANCE_POSTGRES_PORT"], var.base_helm_values.global.env["POSTGRES_PORT"])
      username = try(var.base_helm_values.global.env["SYNC_INSTANCE_POSTGRES_USERNAME"], random_string.postgres_username["sync_instance"].result)
      password = try(var.base_helm_values.global.env["SYNC_INSTANCE_POSTGRES_PASSWORD"], random_password.postgres_password["sync_instance"].result)
      database = "sync_instance"
    }
    sync_project = {
      host     = try(var.base_helm_values.global.env["SYNC_PROJECT_POSTGRES_HOST"], var.base_helm_values.global.env["POSTGRES_HOST"])
      port     = try(var.base_helm_values.global.env["SYNC_PROJECT_POSTGRES_PORT"], var.base_helm_values.global.env["POSTGRES_PORT"])
      username = try(var.base_helm_values.global.env["SYNC_PROJECT_POSTGRES_USERNAME"], random_string.postgres_username["sync_project"].result)
      password = try(var.base_helm_values.global.env["SYNC_PROJECT_POSTGRES_PASSWORD"], random_password.postgres_password["sync_project"].result)
      database = "sync_project"
    }
  }

  kafka_config = {
    broker_urls    = try(var.base_helm_values.global.env["MANAGED_SYNC_KAFKA_BROKER_URLS"], null)
    sasl_username  = try(var.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_USERNAME"], null)
    sasl_password  = try(var.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_PASSWORD"], null)
    sasl_mechanism = try(var.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SASL_MECHANISM"], null)
    ssl_enabled    = try(var.base_helm_values.global.env["MANAGED_SYNC_KAFKA_SSL_ENABLED"], null)
  }

  queue_exporter_config = {
    host     = try(var.microservices["queue-exporter"].host, null)
    port     = try(var.microservices["queue-exporter"].port, null)
    username = try(var.base_helm_values.global.env["MONITOR_QUEUE_EXPORTER_HTTP_USERNAME"], random_string.queue_exporter_username.result)
    password = try(var.base_helm_values.global.env["MONITOR_QUEUE_EXPORTER_HTTP_PASSWORD"], random_password.queue_exporter_password.result)
  }

  managed_sync_secrets = {
    HOST_ENV  = "AWS_K8"
    LOG_LEVEL = try(var.base_helm_values.global.env["LOG_LEVEL"], "debug")

    CLOUD_STORAGE_TYPE                = try(var.base_helm_values.global.env["CLOUD_STORAGE_TYPE"], "MINIO")
    CLOUD_STORAGE_PUBLIC_BUCKET       = coalesce(try(var.base_helm_values.global.env["CLOUD_STORAGE_PUBLIC_BUCKET"], null), try(var.base_helm_values.global.env["MINIO_PUBLIC_BUCKET"], null), null)
    CLOUD_STORAGE_USER                = try(var.base_helm_values.global.env["MINIO_MICROSERVICE_USER"], null)
    CLOUD_STORAGE_PASS                = try(var.base_helm_values.global.env["MINIO_MICROSERVICE_PASS"], null)
    CLOUD_STORAGE_MANAGED_SYNC_BUCKET = coalesce(try(var.base_helm_values.global.env["MINIO_MANAGED_SYNC_BUCKET"], null), "managed-sync")
    CLOUD_STORAGE_PUBLIC_URL          = coalesce(try(var.base_helm_values.global.env["CLOUD_STORAGE_PUBLIC_URL"], null), try(var.base_helm_values.global.env["MINIO_PUBLIC_URL"], null), "https://s3.${var.aws_region}.amazonaws.com")

    // TODO: make `MANAGED_SYNC_URL` communicate via private DNS instead of open internet
    MANAGED_SYNC_URL       = try(var.base_helm_values.global.env["MANAGED_SYNC_URL"], "https://sync.${var.domain}")
    PARAGON_PROXY_BASE_URL = try("http://worker-proxy:${var.microservices["worker-proxy"].port}", null)
    PARAGON_ZEUS_BASE_URL  = try("http://zeus:${var.microservices.zeus.port}", null)

    MANAGED_SYNC_PRIVATE_KEY     = replace(tls_private_key.managed_sync_signing_key.private_key_pem, "\n", "\\n")
    MANAGED_SYNC_AUTH_PUBLIC_KEY = replace(tls_private_key.managed_sync_signing_key.public_key_pem, "\n", "\\n")

    MANAGED_SYNC_ETCD_HOSTS = join(",", [for i in range(3) : "http://etcd-${i}.etcd-headless:2379"])

    MANAGED_SYNC_KAFKA_BROKER_URLS    = local.kafka_config.broker_urls
    MANAGED_SYNC_KAFKA_SASL_USERNAME  = local.kafka_config.sasl_username
    MANAGED_SYNC_KAFKA_SASL_PASSWORD  = local.kafka_config.sasl_password
    MANAGED_SYNC_KAFKA_SASL_MECHANISM = local.kafka_config.sasl_mechanism
    MANAGED_SYNC_KAFKA_SSL_ENABLED    = local.kafka_config.ssl_enabled

    MANAGED_SYNC_REDIS_URL             = try(var.base_helm_values.global.env["MANAGED_SYNC_REDIS_URL"], "${var.base_helm_values.global.env["REDIS_HOST"]}:${var.base_helm_values.global.env["REDIS_PORT"]}/0")
    MANAGED_SYNC_REDIS_CLUSTER_ENABLED = try(var.base_helm_values.global.env["MANAGED_SYNC_REDIS_CLUSTER_ENABLED"], "false")
    MANAGED_SYNC_REDIS_TLS_ENABLED     = try(var.base_helm_values.global.env["MANAGED_SYNC_REDIS_TLS_ENABLED"], "false")

    SYNC_INSTANCE_POSTGRES_HOST        = local.postgres_config.sync_instance.host
    SYNC_INSTANCE_POSTGRES_PORT        = local.postgres_config.sync_instance.port
    SYNC_INSTANCE_POSTGRES_USERNAME    = local.postgres_config.sync_instance.username
    SYNC_INSTANCE_POSTGRES_PASSWORD    = local.postgres_config.sync_instance.password
    SYNC_INSTANCE_POSTGRES_DATABASE    = local.postgres_config.sync_instance.database
    SYNC_INSTANCE_POSTGRES_SSL_ENABLED = true

    SYNC_PROJECT_POSTGRES_HOST        = local.postgres_config.sync_project.host
    SYNC_PROJECT_POSTGRES_PORT        = local.postgres_config.sync_project.port
    SYNC_PROJECT_POSTGRES_USERNAME    = local.postgres_config.sync_project.username
    SYNC_PROJECT_POSTGRES_PASSWORD    = local.postgres_config.sync_project.password
    SYNC_PROJECT_POSTGRES_DATABASE    = local.postgres_config.sync_project.database
    SYNC_PROJECT_POSTGRES_SSL_ENABLED = true

    OPENFGA_HTTP_URL             = "http://openfga:6200"
    OPENFGA_POSTGRES_HOST        = local.postgres_config.openfga.host
    OPENFGA_POSTGRES_PORT        = local.postgres_config.openfga.port
    OPENFGA_POSTGRES_USERNAME    = local.postgres_config.openfga.username
    OPENFGA_POSTGRES_PASSWORD    = local.postgres_config.openfga.password
    OPENFGA_POSTGRES_DATABASE    = local.postgres_config.openfga.database
    OPENFGA_POSTGRES_SSL_ENABLED = true
    OPENFGA_POSTGRES_URI         = "postgres://${local.postgres_config.openfga.username}:${local.postgres_config.openfga.password}@${local.postgres_config.openfga.host}:${local.postgres_config.openfga.port}/${local.postgres_config.openfga.database}?sslmode=prefer"
    OPENFGA_AUTH_PRESHARED_KEY   = random_string.openfga_preshared_key.result

    ADMIN_POSTGRES_HOST        = local.postgres_config.admin.host
    ADMIN_POSTGRES_PORT        = local.postgres_config.admin.port
    ADMIN_POSTGRES_USERNAME    = local.postgres_config.admin.username
    ADMIN_POSTGRES_PASSWORD    = local.postgres_config.admin.password
    ADMIN_POSTGRES_DATABASE    = local.postgres_config.admin.database
    ADMIN_POSTGRES_SSL_ENABLED = true

    OPENFGA_HTTP_PORT           = 6200
    OPENFGA_GRPC_PORT           = 6201
    OPENFGA_AUTH_METHOD         = "preshared"
    OPENFGA_AUTH_PRESHARED_KEYS = sha256(local.postgres_config.openfga.password)
    OPENFGA_HTTP_URL            = "http://openfga:${6200}"

    # monitoring config
    MONITOR_MANAGED_SYNC_ENABLED = true

    MONITOR_MANAGED_SYNC_KAFKA_BROKER_URLS    = local.kafka_config.broker_urls
    MONITOR_MANAGED_SYNC_KAFKA_SASL_USERNAME  = local.kafka_config.sasl_username
    MONITOR_MANAGED_SYNC_KAFKA_SASL_PASSWORD  = local.kafka_config.sasl_password
    MONITOR_MANAGED_SYNC_KAFKA_SASL_MECHANISM = local.kafka_config.sasl_mechanism
    MONITOR_MANAGED_SYNC_KAFKA_SSL_ENABLED    = local.kafka_config.ssl_enabled

    MONITOR_QUEUE_EXPORTER_HTTP_USERNAME              = local.queue_exporter_config.username
    MONITOR_QUEUE_EXPORTER_HTTP_PASSWORD              = local.queue_exporter_config.password
    MONITOR_MANAGED_SYNC_QUEUE_EXPORTER_HOST          = local.queue_exporter_config.host
    MONITOR_MANAGED_SYNC_QUEUE_EXPORTER_PORT          = local.queue_exporter_config.port
    MONITOR_MANAGED_SYNC_QUEUE_EXPORTER_HTTP_USERNAME = local.queue_exporter_config.username
    MONITOR_MANAGED_SYNC_QUEUE_EXPORTER_HTTP_PASSWORD = local.queue_exporter_config.password

    MONITOR_MANAGED_SYNC_POSTGRES_HOST        = local.postgres_config.admin.host
    MONITOR_MANAGED_SYNC_POSTGRES_PORT        = local.postgres_config.admin.port
    MONITOR_MANAGED_SYNC_POSTGRES_USERNAME    = local.postgres_config.admin.username
    MONITOR_MANAGED_SYNC_POSTGRES_PASSWORD    = local.postgres_config.admin.password
    MONITOR_MANAGED_SYNC_POSTGRES_DATABASE    = local.postgres_config.admin.database
    MONITOR_MANAGED_SYNC_POSTGRES_SSL_ENABLED = true

    # not used at the moment
    # MONITOR_KUBE_STATE_METRICS_HTTP_USERNAME = ""
    # MONITOR_KUBE_STATE_METRICS_HTTP_PASSWORD = ""
  }
}

resource "random_string" "postgres_username" {
  for_each = toset(local.postgres_instances)

  length  = 16
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "random_password" "postgres_password" {
  for_each = toset(local.postgres_instances)

  length  = 32
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "random_string" "queue_exporter_username" {
  length  = 16
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "random_password" "queue_exporter_password" {
  length  = 32
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "random_string" "openfga_preshared_key" {
  length  = 16
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "tls_private_key" "managed_sync_signing_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

