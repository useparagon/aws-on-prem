output "s3" {
  value = {
    bucket = var.disable_cloudtrail ? null : aws_s3_bucket.cloudtrail[0].bucket
  }
}
