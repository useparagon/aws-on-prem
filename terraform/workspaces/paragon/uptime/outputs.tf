output "webhook" {
  value     = local.enabled ? betteruptime_grafana_integration.webhook[0].webhook_url : ""
  sensitive = true
}

output "monitors" {
  value = betteruptime_monitor.monitor[*].pronounceable_name
}

output "microservices" {
  value = keys(var.microservices)
}
