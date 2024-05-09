output "webhook" {
  value     = local.enabled ? betteruptime_grafana_integration.webhook[0].webhook_url : ""
  sensitive = true
}

output "monitors" {
  value = keys(betteruptime_monitor.monitor)
}

output "microservices" {
  value = keys(var.microservices)
}
