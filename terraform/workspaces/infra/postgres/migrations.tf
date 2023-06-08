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

# incase migrating from single instance to multi, migrate db to zeus so data not erased
moved {
  from = aws_db_instance.postgres["paragon"]
  to   = aws_db_instance.postgres["zeus"]
}
