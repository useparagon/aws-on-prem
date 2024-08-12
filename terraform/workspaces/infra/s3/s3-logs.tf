resource "aws_s3_bucket" "logs" {
  count = var.disable_logs ? 0 : 1

  bucket        = "${var.workspace}-logs"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.disable_logs ? 0 : 1
  bucket = aws_s3_bucket.logs[count.index].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.disable_logs ? 0 : 1
  bucket = aws_s3_bucket.logs[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  count = var.disable_logs ? 0 : 1

  statement {
    sid     = "AllowAccessLogs"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    resources = [
      "${aws_s3_bucket.logs[count.index].arn}",
      "${aws_s3_bucket.logs[count.index].arn}/access_logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }

  statement {
    sid = "AllowAppLogs"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.logs[count.index].arn}",
      "${aws_s3_bucket.logs[count.index].arn}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logs_bucket" {
  count = var.disable_logs ? 0 : 1

  bucket = aws_s3_bucket.logs[count.index].id
  policy = data.aws_iam_policy_document.logs_bucket_policy[count.index].json
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.disable_logs ? 0 : 1

  bucket = aws_s3_bucket.logs[count.index].id

  rule {
    id     = "abort-incomplete"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "expire"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}
