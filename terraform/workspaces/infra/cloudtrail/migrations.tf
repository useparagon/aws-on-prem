# v2.0.0 -> v2.1.0: conditionally create cloudtrail bucket depending on `disable_cloudtrail` argument
moved {
  from = aws_s3_bucket.cloudtrail
  to   = aws_s3_bucket.cloudtrail[0]
}

moved {
  from = aws_s3_bucket_policy.cloudtrail
  to   = aws_s3_bucket_policy.aws_s3_bucket_policy[0]
}

moved {
  from = aws_s3_bucket_public_access_block.cloudtrail
  to   = aws_s3_bucket_public_access_block.aws_s3_bucket_policy[0]
}
