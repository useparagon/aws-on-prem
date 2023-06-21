resource "aws_s3_bucket" "logs" {
  count = var.disable_logs ? 0 : 1

  bucket        = "${var.workspace}-logs"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = var.disable_logs ? 0 : 1
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
    sid     = "AllowPutObjects"
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
}

resource "aws_s3_bucket_policy" "logs_bucket" {
  count = var.disable_logs ? 0 : 1

  bucket = aws_s3_bucket.logs[count.index].id
  policy = data.aws_iam_policy_document.logs_bucket_policy[count.index].json
}