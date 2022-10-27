data "aws_caller_identity" "current" {}

resource "aws_iam_role" "super_admin" {
  name = "${var.workspace}-eks-super-admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowBastionAssumeSuperAdmin"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workspace}-bastion"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.workspace}-eks-super-admin"
  }
}
