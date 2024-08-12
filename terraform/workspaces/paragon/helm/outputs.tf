output "release_ingress" {
  value = helm_release.ingress
}

output "release_paragon_on_prem" {
  value = helm_release.paragon_on_prem
}

output "openobserve_email" {
  value = local.openobserve_email
}

output "openobserve_password" {
  value     = local.openobserve_password
  sensitive = true
}
