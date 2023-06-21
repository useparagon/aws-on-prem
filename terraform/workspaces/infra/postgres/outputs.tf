output "rds" {
  value = {
    for key, value in local.postgres_instances :
    key => {
      host     = aws_db_instance.postgres[key].address
      port     = aws_db_instance.postgres[key].port
      user     = random_string.postgres_root_username[key].result
      password = random_string.postgres_root_password[key].result
      database = aws_db_instance.postgres[key].name
    }
  }

  sensitive = true
}
