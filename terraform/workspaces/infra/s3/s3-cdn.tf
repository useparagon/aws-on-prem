resource "aws_s3_bucket" "cdn" {
  bucket        = "${var.workspace}-cdn"
  force_destroy = var.force_destroy

  dynamic "logging" {
    for_each = var.disable_cloudtrail ? [] : ["true"]
    content {
      target_bucket = var.cloudtrail_s3_bucket
      target_prefix = "${var.workspace}-cdn/"
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

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "cdn" {
  bucket = aws_s3_bucket.cdn.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAnonymousReads",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObjectVersion",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.cdn.id}/*"
        }
    ]
}
POLICY

  depends_on = [
    aws_s3_bucket_public_access_block.cdn
  ]
}

resource "aws_s3_bucket_public_access_block" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
