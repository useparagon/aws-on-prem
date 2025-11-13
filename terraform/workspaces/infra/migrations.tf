# v2.0.0 -> v2.1.0
# Added support for overriding resource names with `organization` variable
moved {
  from = random_string.app
  to   = random_string.app[0]
}

#
# aws-on-prem -> enterprise
#

# s3 module renamed to storage
moved {
  from = module.s3.aws_iam_access_key.app
  to   = module.storage.aws_iam_access_key.app
}
moved {
  from = module.s3.aws_iam_user_policy.app
  to   = module.storage.aws_iam_user_policy.app
}
moved {
  from = module.s3.aws_iam_user.app
  to   = module.storage.aws_iam_user.app
}
moved {
  from = module.s3.aws_s3_bucket_lifecycle_configuration.expiration
  to   = module.storage.aws_s3_bucket_lifecycle_configuration.expiration
}
moved {
  from = module.s3.aws_s3_bucket_lifecycle_configuration.logs[0]
  to   = module.storage.aws_s3_bucket_lifecycle_configuration.logs[0]
}
moved {
  from = module.s3.aws_s3_bucket_ownership_controls.cdn
  to   = module.storage.aws_s3_bucket_ownership_controls.cdn
}
moved {
  from = module.s3.aws_s3_bucket_ownership_controls.logs[0]
  to   = module.storage.aws_s3_bucket_ownership_controls.logs[0]
}
moved {
  from = module.s3.aws_s3_bucket_policy.app_bucket
  to   = module.storage.aws_s3_bucket_policy.app_bucket
}
moved {
  from = module.s3.aws_s3_bucket_policy.cdn
  to   = module.storage.aws_s3_bucket_policy.cdn
}
moved {
  from = module.s3.aws_s3_bucket_policy.logs_bucket[0]
  to   = module.storage.aws_s3_bucket_policy.logs_bucket[0]
}
moved {
  from = module.s3.aws_s3_bucket_public_access_block.app
  to   = module.storage.aws_s3_bucket_public_access_block.app
}
moved {
  from = module.s3.aws_s3_bucket_public_access_block.cdn
  to   = module.storage.aws_s3_bucket_public_access_block.cdn
}
moved {
  from = module.s3.aws_s3_bucket_server_side_encryption_configuration.cdn
  to   = module.storage.aws_s3_bucket_server_side_encryption_configuration.cdn
}
moved {
  from = module.s3.aws_s3_bucket_server_side_encryption_configuration.logs[0]
  to   = module.storage.aws_s3_bucket_server_side_encryption_configuration.logs[0]
}
moved {
  from = module.s3.aws_s3_bucket.app
  to   = module.storage.aws_s3_bucket.app
}
moved {
  from = module.s3.aws_s3_bucket.cdn
  to   = module.storage.aws_s3_bucket.cdn
}
moved {
  from = module.s3.aws_s3_bucket.logs[0]
  to   = module.storage.aws_s3_bucket.logs[0]
}
moved {
  from = module.s3.data.aws_caller_identity.current
  to   = module.storage.data.aws_caller_identity.current
}
moved {
  from = module.s3.data.aws_elb_service_account.main
  to   = module.storage.data.aws_elb_service_account.main
}
moved {
  from = module.s3.data.aws_iam_policy_document.app_bucket_policy
  to   = module.storage.data.aws_iam_policy_document.app_bucket_policy
}
moved {
  from = module.s3.data.aws_iam_policy_document.logs_bucket_policy[0]
  to   = module.storage.data.aws_iam_policy_document.logs_bucket_policy[0]
}
moved {
  from = module.s3.random_string.minio_microservice_pass
  to   = module.storage.random_string.minio_microservice_pass
}
moved {
  from = module.s3.random_string.minio_microservice_user
  to   = module.storage.random_string.minio_microservice_user
}
