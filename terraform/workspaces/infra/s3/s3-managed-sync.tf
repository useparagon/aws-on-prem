resource "aws_s3_bucket" "managed_sync" {
  count         = var.managed_sync_enabled ? 1 : 0
  bucket        = "${var.workspace}-managed-sync"
  acl           = "private"
  force_destroy = var.force_destroy

  dynamic "logging" {
    for_each = var.disable_cloudtrail ? [] : ["true"]
    content {
      target_bucket = var.cloudtrail_s3_bucket
      target_prefix = "${var.workspace}-managed-sync/"
    }
  }

  versioning {
    enabled = true
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].id

  rule {
    id = "expiration"

    expiration {
      days = var.app_bucket_expiration
    }

    noncurrent_version_expiration {
      noncurrent_days = var.app_bucket_expiration
    }

    status = "Enabled"
  }
}

data "aws_iam_policy_document" "managed_sync" {
  count = var.managed_sync_enabled ? 1 : 0
  statement {
    sid       = "AllowSSLRequestsOnly"
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.managed_sync[0].arn}", "${aws_s3_bucket.managed_sync[0].arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "managed_sync" {
  count  = var.managed_sync_enabled ? 1 : 0
  bucket = aws_s3_bucket.managed_sync[0].id
  policy = data.aws_iam_policy_document.managed_sync[0].json
}
