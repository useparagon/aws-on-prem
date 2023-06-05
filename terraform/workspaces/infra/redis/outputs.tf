output "elasticache" {
  value = var.multi_redis ? {
    for key, value in local.redis_instances :
    key => key == "cache" ? {
      host = aws_elasticache_replication_group.redis[0].configuration_endpoint_address
      port = 6379
      } : {
      host = aws_elasticache_cluster.redis[key].cache_nodes[0].address
      port = aws_elasticache_cluster.redis[key].cache_nodes[0].port
    }
    } : {
    host = aws_elasticache_cluster.redis[0].cache_nodes[0].address
    port = aws_elasticache_cluster.redis[0].cache_nodes[0].port
  }
  sensitive = true
}
