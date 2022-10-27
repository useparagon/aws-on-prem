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
}

output "postgres_port" {
  description = "The port of the postgres database."
  value       = module.postgres.rds.port
}

output "postgres_user" {
  description = "The username of the postgres database."
  value       = module.postgres.rds.user
}

output "postgres_password" {
  description = "The password of the postgres database."
  value       = module.postgres.rds.password
}

output "postgres_database" {
  description = "The database of the postgres database."
  value       = module.postgres.rds.database
}
