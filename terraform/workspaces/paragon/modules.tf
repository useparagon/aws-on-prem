module "alb" {
  source = "./alb"

  aws_workspace = var.aws_workspace
  domain        = var.domain
  microservices = local.microservices

  release_ingress         = module.helm.release_ingress
  release_paragon_on_prem = module.helm.release_paragon_on_prem
}

module "helm" {
  source = "./helm"

  aws_region      = var.aws_region
  aws_workspace   = var.aws_workspace
  cluster_name    = var.cluster_name
  docker_username = var.docker_username
  docker_password = var.docker_password
  docker_email    = var.docker_email
  helm_values     = local.helm_values
  microservices   = local.microservices

  acm_certificate_arn = module.alb.acm_certificate_arn
}