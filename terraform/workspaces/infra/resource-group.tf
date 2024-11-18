resource "random_string" "app" {
  count = var.organization != null ? 0 : 1

  length  = 8
  special = false
  numeric = false
  lower   = true
  upper   = false
}
