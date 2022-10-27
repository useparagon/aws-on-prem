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
