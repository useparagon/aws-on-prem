resource "betteruptime_monitor_group" "group" {
  count = local.enabled ? 1 : 0

  name = var.uptime_company
}

resource "betteruptime_monitor" "monitor" {
  for_each = local.enabled ? var.microservices : {}

  pronounceable_name = "Enterprise ${var.uptime_company} - Microservice ${each.key}"

  check_frequency       = 30  # seconds
  confirmation_period   = 120 # seconds
  domain_expiration     = 14  # days
  expected_status_codes = [200]
  maintenance_timezone  = "Pacific Time (US & Canada)"
  monitor_group_id      = betteruptime_monitor_group.group[0].id
  monitor_type          = "expected_status_code"
  recovery_period       = 60  # seconds
  request_timeout       = 15  # seconds
  ssl_expiration        = 14  # days
  team_wait             = 180 # seconds
  url                   = "${each.value.public_url}${each.value.healthcheck_path}"

  call  = true
  email = true
  push  = true
  sms   = true
}
