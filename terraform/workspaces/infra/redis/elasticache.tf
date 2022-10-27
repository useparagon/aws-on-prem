resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.workspace}-elasticache-subnet"
  subnet_ids = var.private_subnet.*.id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.workspace}-redis"
  engine               = "redis"
  node_type            = var.elasticache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379

  apply_immediately = true

  snapshot_retention_limit = 5
  snapshot_window          = "12:00-14:00"
  maintenance_window       = "tue:16:00-tue:17:00"

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  tags = {
    Cluster = "false"
  }
}
