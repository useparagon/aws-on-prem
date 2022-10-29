output "release_ingress" {
  value = helm_release.ingress
}

output "release_paragon_on_prem" {
  value = helm_release.paragon_on_prem
}