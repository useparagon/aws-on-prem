output "elasticache" {
  value = {
    host = aws_elasticache_cluster.redis.cache_nodes[0].address
    port = aws_elasticache_cluster.redis.cache_nodes[0].port
  }
  sensitive = true
}
