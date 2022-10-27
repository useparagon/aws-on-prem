module "network" {
  source = "./network"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace   = local.workspace
  environment = local.environment

  az_count = var.az_count
  vpc_cidr = var.vpc_cidr
}

module "postgres" {
  source = "./postgres"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace              = local.workspace
  environment            = local.environment
  postgres_version       = var.postgres_version
  rds_instance_class     = var.rds_instance_class

  vpc                = module.network.vpc
  public_subnet      = module.network.public_subnet
  private_subnet     = module.network.private_subnet
  availability_zones = module.network.availability_zones
}
