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

output "minio_root_user" {
  description = "The root username for Minio service."
  value       = module.s3.s3.access_key_id
  sensitive   = true
}

output "minio_root_password" {
  description = "The root password for Minio service."
  value       = module.s3.s3.access_key_secret
  sensitive   = true
}

output "minio_microservice_user" {
  description = "The username for the microservices to connect to Minio."
  value       = module.s3.s3.minio_microservice_user
  sensitive   = true
}

output "minio_microservice_pass" {
  description = "The pass for the microservices to connect to Minio."
  value       = module.s3.s3.minio_microservice_pass
  sensitive   = true
}

output "minio_public_bucket" {
  description = "The public bucket used by Minio."
  value       = module.s3.s3.public_bucket
  sensitive   = true
}

output "minio_private_bucket" {
  description = "The private bucket used by Minio."
  value       = module.s3.s3.private_bucket
  sensitive   = true
}

output "bastion_load_balancer" {
  description = "The url for the bastion load balancer."
  value       = module.bastion.load_balancer.public_dns
  sensitive   = true
}

output "bastion_private_key" {
  description = "The private key for the bastion."
  value       = module.bastion.load_balancer.private_key
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.cluster.eks_cluster.name
}
