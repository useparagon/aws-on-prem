# v2.0.0 -> v2.1.0
# Added support for multiple Redis databases. Used for high volume installations
moved {
  from = aws_elasticache_cluster.redis
  to   = aws_elasticache_cluster.redis["cache"]
}
