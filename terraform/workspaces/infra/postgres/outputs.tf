output "rds" {
  value = {
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    user     = random_string.postgres_root_username.result
    password = random_string.postgres_root_password.result
    database = aws_db_instance.postgres.name
  }
  sensitive = true
}
