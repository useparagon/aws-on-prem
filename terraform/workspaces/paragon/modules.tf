module "alb" {
  source = "./alb"

  acm_certificate_arn      = var.acm_certificate_arn
  aws_workspace            = var.aws_workspace
  domain                   = var.domain
  public_microservices     = local.public_microservices
  public_monitors          = local.public_monitors
  dns_provider             = var.dns_provider
  cloudflare_dns_api_token = var.cloudflare_dns_api_token
  cloudflare_zone_id       = var.cloudflare_zone_id

  release_ingress         = module.helm.release_ingress
  release_paragon_on_prem = module.helm.release_paragon_on_prem
}

module "helm" {
  source = "./helm"

  aws_region             = var.aws_region
  aws_workspace          = var.aws_workspace
  cluster_name           = var.cluster_name
  docker_email           = var.docker_email
  docker_password        = var.docker_password
  docker_registry_server = var.docker_registry_server
  docker_username        = var.docker_username
  feature_flags_content  = local.feature_flags_content
  flipt_options          = local.flipt_options
  helm_values            = local.helm_values
  ingress_scheme         = var.ingress_scheme
  k8_version             = var.k8_version
  logs_bucket            = var.logs_bucket
  managed_sync_enabled   = var.managed_sync_enabled
  managed_sync_version   = var.managed_sync_version
  microservices          = local.microservices
  monitor_version        = local.monitor_version
  monitors               = local.monitors
  monitors_enabled       = var.monitors_enabled
  openobserve_email      = var.openobserve_email
  openobserve_password   = var.openobserve_password
  public_microservices   = local.public_microservices
  public_monitors        = local.public_monitors

  acm_certificate_arn = module.alb.acm_certificate_arn
}

module "managed_sync_config" {
  source = "./helm-config"
  count  = var.managed_sync_enabled ? 1 : 0

  aws_region       = var.aws_region
  base_helm_values = local.base_helm_values
  domain           = var.domain
  microservices    = local.microservices
}

module "monitors" {
  source = "./monitors"
  count  = var.monitors_enabled ? 1 : 0

  aws_workspace                               = var.aws_workspace
  grafana_aws_access_key_id                   = try(local.base_helm_values.global.env["MONITOR_GRAFANA_AWS_ACCESS_ID"], null)
  grafana_aws_secret_access_key               = try(local.base_helm_values.global.env["MONITOR_GRAFANA_AWS_SECRET_KEY"], null)
  grafana_admin_email                         = try(local.base_helm_values.global.env["MONITOR_GRAFANA_SECURITY_ADMIN_USER"], null)
  grafana_admin_password                      = try(local.base_helm_values.global.env["MONITOR_GRAFANA_SECURITY_ADMIN_PASSWORD"], null)
  grafana_customer_webhook_url                = var.monitor_grafana_customer_webhook_url
  grafana_customer_defined_alerts_webhook_url = var.monitor_grafana_customer_defined_alerts_webhook_url
  pgadmin_admin_email                         = try(local.base_helm_values.global.env["MONITOR_PGADMIN_EMAIL"], null)
  pgadmin_admin_password                      = try(local.base_helm_values.global.env["MONITOR_PGADMIN_PASSWORD"], null)
}

module "uptime" {
  source = "./uptime"

  uptime_api_token = var.uptime_api_token
  uptime_company   = coalesce(var.uptime_company, var.organization)
  microservices    = local.public_microservices
}
