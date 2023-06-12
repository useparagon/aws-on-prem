resource "random_string" "minio_microservice_user" {
  length  = 10
  special = false
  numeric = true
  lower   = true
  upper   = false
}

resource "random_string" "minio_microservice_pass" {
  length  = 10
  special = false
  numeric = true
  lower   = true
  upper   = false
}
