output "vpc_id" {
  description = "The id of the VPC."
  value       = module.network.vpc.id
}

output "public_subnet_ids" {
  description = "The ids of the public subnets."
  value       = module.network.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "The ids of the private subnets."
  value       = module.network.private_subnet[*].id
}

output "postgres_host" {
  description = "The host of the postgres database."
  value       = module.postgres.rds.host
  sensitive   = true
}

output "postgres_port" {
  description = "The port of the postgres database."
  value       = module.postgres.rds.port
  sensitive   = true
}

output "postgres_user" {
  description = "The username of the postgres database."
  value       = module.postgres.rds.user
  sensitive   = true
}

output "postgres_password" {
  description = "The password of the postgres database."
  value       = module.postgres.rds.password
  sensitive   = true
}

output "postgres_database" {
  description = "The database of the postgres database."
  value       = module.postgres.rds.database
  sensitive   = true
}

output "redis_host" {
  description = "The host of the redis database."
  value       = module.redis.elasticache.host
  sensitive   = true
}

output "redis_port" {
  description = "The port of the redis database."
  value       = module.redis.elasticache.port
  sensitive   = true
}

output "minio_root_user" {
  description = "The root username for Minio service."
  value       = module.s3.s3.access_key_id
  sensitive   = true
}

output "minio_root_pass" {
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
