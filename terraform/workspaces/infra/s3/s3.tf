resource "aws_s3_bucket" "app" {
  bucket        = var.workspace
  acl           = "private"
  force_destroy = var.force_destroy

  logging {
    target_bucket = var.cloudtrail_s3_bucket
    target_prefix = "${var.workspace}/"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expiration" {
  bucket = aws_s3_bucket.app.id

  rule {
    id = "expiration"

    expiration {
      days = var.app_bucket_expiration
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket" "cdn" {
  bucket        = "${var.workspace}-cdn"
  acl           = "public-read"
  force_destroy = var.force_destroy

  logging {
    target_bucket = var.cloudtrail_s3_bucket
    target_prefix = "${var.workspace}-cdn/"
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

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.app.arn}", "${aws_s3_bucket.app.arn}/*"]

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

data "aws_iam_policy_document" "cdn_bucket_policy" {
  statement {
    sid = "AllowAnonymousReads"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.cdn.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  # NOTE: Insecure (non-SSL) requests are allowed for this bucket otherwise requests from Minio fail
}

resource "aws_s3_bucket_policy" "app_bucket" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}

resource "aws_s3_bucket_policy" "cdn_bucket" {
  bucket = aws_s3_bucket.cdn.id
  policy = data.aws_iam_policy_document.cdn_bucket_policy.json
}

resource "aws_iam_user" "app" {
  name = "${var.workspace}-s3-user"

  tags = {
    Name = "${var.workspace}-s3-user"
  }
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app" {
  name = "${var.workspace}-s3-policy"
  user = aws_iam_user.app.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadBucketOperations",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:GetBucketVersioning",
        "s3:GetEncryptionConfiguration"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.app.arn}",
        "${aws_s3_bucket.cdn.arn}"
      ]
    },
    {
      "Sid": "AllowReadObjectOperations",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectRetention",
        "s3:GetObjectRetention"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.app.arn}/*",
        "${aws_s3_bucket.cdn.arn}/*"
      ]
    },
    {
      "Sid": "AllowPutAndDeleteObjectOperations",
      "Action": [
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:PutObjectLegalHold"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.app.arn}/*",
        "${aws_s3_bucket.cdn.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "random_string" "minio_microservice_user" {
  length  = 10
  special = false
  numeric = true
  lower   = true
  upper   = false
}

resource "random_string" "minio_microservice_pass" {
  length  = 10
  special = false
  numeric = false
  lower   = true
  upper   = false
}
