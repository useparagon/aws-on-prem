output "workspace" {
  description = "The resource group that all resources are associated with."
  value       = local.workspace
}

output "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
  value       = local.environment
}

output "postgres" {
  description = "Connection info for Postgres."
  value       = module.postgres.rds
  sensitive   = true
}

output "redis" {
  description = "Connection information for Redis."
  value       = module.redis.elasticache
  sensitive   = true
}

output "logs_bucket" {
  description = "The bucket used to store system logs."
  value       = module.s3.s3.logs_bucket
  sensitive   = true
}

output "kafka_broker_urls" {
  description = "The broker URLs for Kafka."
  value       = var.managed_sync_enabled ? module.kafka[0].cluster_bootstrap_brokers_sasl_scram : ""
  sensitive   = true
}

output "kafka_sasl_username" {
  description = "The SASL username for Kafka."
  value       = var.managed_sync_enabled ? module.kafka[0].kafka_credentials.username : ""
  sensitive   = true
}

output "kafka_sasl_password" {
  description = "The SASL password for Kafka."
  value       = var.managed_sync_enabled ? module.kafka[0].kafka_credentials.password : ""
  sensitive   = true
}

output "kafka_sasl_mechanism" {
  description = "The SASL mechanism for Kafka."
  value       = var.managed_sync_enabled ? module.kafka[0].kafka_credentials.mechanism : ""
  sensitive   = true
}

output "kafka_tls_enabled" {
  description = "Whether TLS is enabled for Kafka."
  value       = var.managed_sync_enabled ? module.kafka[0].cluster_tls_enabled : ""
  sensitive   = true
}

output "bastion_public_dns" {
  description = "The URL for the bastion server."
  value       = module.bastion.connection.bastion_dns
  sensitive   = true
}

output "bastion_private_key" {
  description = "The private key for the bastion."
  value       = module.bastion.connection.private_key
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.cluster.eks_cluster.name
}

locals {
  db_info = [for r in module.postgres.rds : r][0]
}

output "paragon_config" {
  description = "Required configuration for Paragon deployment"
  sensitive   = true
  value       = <<OUTPUT
    KAFKA_BROKER_URLS: ${var.managed_sync_enabled ? module.kafka[0].cluster_bootstrap_brokers_sasl_scram : ""}
    KAFKA_SASL_USERNAME: ${var.managed_sync_enabled ? module.kafka[0].kafka_credentials.username : ""}
    KAFKA_SASL_PASSWORD: ${var.managed_sync_enabled ? module.kafka[0].kafka_credentials.password : ""}
    KAFKA_SASL_MECHANISM: ${var.managed_sync_enabled ? module.kafka[0].kafka_credentials.mechanism : ""}
    KAFKA_SSL_ENABLED: ${var.managed_sync_enabled ? module.kafka[0].cluster_tls_enabled : ""}

    POSTGRES_HOST: ${local.db_info.host}
    POSTGRES_PORT: ${local.db_info.port}
    POSTGRES_USER: ${local.db_info.user}
    POSTGRES_PASSWORD: ${local.db_info.password == null ? "" : local.db_info.password}
    POSTGRES_DATABASE: ${local.db_info.database}

    REDIS_HOST: ${module.redis.elasticache.cache.host}
    REDIS_PORT: ${module.redis.elasticache.cache.port}
  OUTPUT
}
