output "s3" {
  value = {
    bucket = aws_s3_bucket.cloudtrail.bucket
  }
}
