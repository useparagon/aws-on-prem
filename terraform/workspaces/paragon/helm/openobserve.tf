resource "random_password" "openobserve" {
  length  = 32
  lower   = true
  numeric = true
  special = false
  upper   = true
}
