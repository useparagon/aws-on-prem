module "network" {
  source = "./network"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace        = local.workspace
  environment      = local.environment
  az_count         = var.az_count
  vpc_cidr         = var.vpc_cidr
  vpc_cidr_newbits = var.vpc_cidr_newbits
}

module "cloudtrail" {
  source = "./cloudtrail"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace                   = local.workspace
  environment                 = local.environment
  master_guardduty_account_id = var.master_guardduty_account_id
  mfa_enabled                 = var.mfa_enabled
  disable_cloudtrail          = var.disable_cloudtrail
  force_destroy               = var.disable_deletion_protection
}

module "postgres" {
  source = "./postgres"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace                   = local.workspace
  environment                 = local.environment
  postgres_version            = var.postgres_version
  rds_instance_class          = var.rds_instance_class
  disable_deletion_protection = var.disable_deletion_protection
  multi_az_enabled            = var.multi_az_enabled
  multi_postgres              = var.multi_postgres

  vpc                = module.network.vpc
  public_subnet      = module.network.public_subnet
  private_subnet     = module.network.private_subnet
  availability_zones = module.network.availability_zones
}

module "redis" {
  source = "./redis"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace             = local.workspace
  environment           = local.environment
  elasticache_node_type = var.elasticache_node_type
  multi_az_enabled      = var.multi_az_enabled
  multi_redis           = var.multi_redis

  vpc            = module.network.vpc
  public_subnet  = module.network.public_subnet
  private_subnet = module.network.private_subnet
}

module "s3" {
  source = "./s3"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace          = local.workspace
  environment        = local.environment
  disable_cloudtrail = var.disable_cloudtrail

  cloudtrail_s3_bucket  = var.disable_cloudtrail ? null : module.cloudtrail.s3.bucket
  force_destroy         = var.disable_deletion_protection
  app_bucket_expiration = var.app_bucket_expiration
}

module "cluster" {
  source = "./cluster"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace                        = local.workspace
  environment                      = local.environment
  k8_version                       = var.k8_version
  k8_ondemand_node_instance_type   = local.k8_ondemand_node_instance_type
  k8_spot_node_instance_type       = local.k8_spot_node_instance_type
  k8_spot_instance_percent         = var.k8_spot_instance_percent
  k8_min_node_count                = var.k8_min_node_count
  k8_max_node_count                = var.k8_max_node_count
  eks_addon_ebs_csi_driver_enabled = var.eks_addon_ebs_csi_driver_enabled
  eks_admin_user_arns              = local.eks_admin_user_arns

  vpc              = module.network.vpc
  public_subnet    = module.network.public_subnet
  private_subnet   = module.network.private_subnet
  bastion_role_arn = module.bastion.bastion_role_arn
}

module "bastion" {
  source = "./bastion"

  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_session_token     = var.aws_session_token

  workspace     = local.workspace
  environment   = local.environment
  ssh_whitelist = local.ssh_whitelist

  vpc_id              = module.network.vpc.id
  public_subnet       = module.network.public_subnet
  private_subnet      = module.network.private_subnet
  cluster_super_admin = module.cluster.cluster_super_admin
  force_destroy       = var.disable_deletion_protection
}
