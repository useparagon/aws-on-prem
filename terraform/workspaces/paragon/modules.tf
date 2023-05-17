module "alb" {
  source = "./alb"

  aws_workspace       = var.aws_workspace
  domain              = var.domain
  microservices       = local.microservices
  public_monitors     = local.public_monitors
  acm_certificate_arn = var.acm_certificate_arn

  release_ingress         = module.helm.release_ingress
  release_paragon_on_prem = module.helm.release_paragon_on_prem
}

module "helm" {
  source = "./helm"

  acm_certificate_arn = module.alb.acm_certificate_arn
  aws_region          = var.aws_region
  aws_workspace       = var.aws_workspace
  cluster_name        = var.cluster_name
  docker_email        = var.docker_email
  docker_password     = var.docker_password
  docker_username     = var.docker_username
  helm_values         = local.helm_values
  lb_logs_bucket      = var.lb_logs_bucket
  microservices       = local.microservices
  monitor_version     = var.monitor_version
  monitors            = local.monitors
  monitors_enabled    = var.monitors_enabled
  public_monitors     = local.public_monitors
}

module "monitors" {
  source = "./monitors"
  count  = var.monitors_enabled ? 1 : 0

  aws_workspace                 = var.aws_workspace
  grafana_aws_access_key_id     = try(var.helm_values.global.env["MONITOR_GRAFANA_AWS_ACCESS_ID"], null)
  grafana_aws_secret_access_key = try(var.helm_values.global.env["MONITOR_GRAFANA_AWS_SECRET_KEY"], null)
  grafana_admin_email           = try(var.helm_values.global.env["MONITOR_GRAFANA_SECURITY_ADMIN_USER"], null)
  grafana_admin_password        = try(var.helm_values.global.env["MONITOR_GRAFANA_SECURITY_ADMIN_PASSWORD"], null)
  pgadmin_admin_email           = try(var.helm_values.global.env["MONITOR_PGADMIN_EMAIL"], null)
  pgadmin_admin_password        = try(var.helm_values.global.env["MONITOR_PGADMIN_PASSWORD"], null)
}
