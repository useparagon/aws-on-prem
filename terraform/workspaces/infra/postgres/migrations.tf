# v2.0.0 -> v2.1.0
# Added support for multiple Postgres databases. Used for high volume installations
moved {
  from = aws_db_instance.postgres
  to   = aws_db_instance.postgres["paragon"]
}

moved {
  from = random_string.postgres_root_username
  to   = random_string.postgres_root_username["paragon"]
}

moved {
  from = random_string.postgres_root_password
  to   = random_string.postgres_root_password["paragon"]
}
