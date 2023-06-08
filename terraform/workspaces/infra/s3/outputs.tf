output "s3" {
  value = {
    access_key_id           = aws_iam_access_key.app.id
    access_key_secret       = aws_iam_access_key.app.secret
    private_bucket          = aws_s3_bucket.app.bucket
    public_bucket           = aws_s3_bucket.cdn.bucket
    logs_bucket             = !var.disable_logs ? aws_s3_bucket.logs[0].bucket : null
    minio_microservice_user = random_string.minio_microservice_user.result
    minio_microservice_pass = random_string.minio_microservice_pass.result
  }
  sensitive = true
}
