resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.main.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.app.id

  tags = {
    Name = "${var.workspace}-vpc-logs"
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name_prefix       = "${var.workspace}-vpc-logs"
  retention_in_days = 365

  tags = {
    Name = "${var.workspace}-vpc-logs"
  }
}
