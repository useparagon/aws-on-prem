output "s3" {
  value = {
    access_key_id           = aws_iam_access_key.app.id
    access_key_secret       = aws_iam_access_key.app.secret
    private_bucket          = aws_s3_bucket.app.bucket
    public_bucket           = aws_s3_bucket.cdn.bucket
    lb_logs_bucket          = aws_s3_bucket.lb_logs.bucket
    minio_microservice_user = random_string.minio_microservice_user.result
    minio_microservice_pass = random_string.minio_microservice_pass.result
  }
  sensitive = true
}
