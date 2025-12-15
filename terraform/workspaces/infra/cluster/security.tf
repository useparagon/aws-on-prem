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

resource "aws_iam_role" "node_role" {
  name        = "${var.workspace}-eks-node-role"
  description = "role for eks node group"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "",
        Effect : "Allow",
        Principal : {
          Service : "ec2.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.workspace}-eks"
  }
}

resource "aws_iam_policy" "eks_worker_policy" {
  name        = "${var.workspace}-eks-worker-policy"
  description = "Worker policy for the ALB Ingress."
  policy      = file("./templates/eks/eks-worker-policy.tpl.json")

  tags = {
    Name = "${var.workspace}-eks-worker-policy"
  }
}

resource "aws_iam_role_policy_attachment" "custom_worker_policy_attachment" {
  role       = aws_iam_role.node_role.name
  policy_arn = aws_iam_policy.eks_worker_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy" "aws_ebs_csi_driver" {
  count = var.eks_addon_ebs_csi_driver_enabled ? 1 : 0

  name_prefix = "${var.workspace}-ebs"
  policy      = data.aws_iam_policy_document.aws_ebs_csi_driver[0].json

  tags = {
    Name = "${var.workspace}-eks"
  }
}

data "aws_iam_policy_document" "aws_ebs_csi_driver" {
  count = var.eks_addon_ebs_csi_driver_enabled ? 1 : 0

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.id}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.current.id}:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateVolume",
        "CreateSnapshot",
      ]
    }
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:${data.aws_partition.current.id}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.current.id}:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:DeleteTags"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/kubernetes.io/cluster/*"
      values   = ["owned"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/cluster/*"
      values   = ["owned"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [module.ebs_kms_key.key_arn]
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [module.ebs_kms_key.key_arn]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
  }
}

module "aws_ebs_csi_driver_iam_role" {
  count = var.eks_addon_ebs_csi_driver_enabled ? 1 : 0

  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "4.24.1"
  create_role      = true
  role_description = "EBS CSI Driver Role"
  role_name_prefix = "${var.workspace}-eks-csi-"
  provider_url     = module.eks.oidc_provider
  role_policy_arns = [aws_iam_policy.aws_ebs_csi_driver[0].arn]
  oidc_fully_qualified_audiences = [
    "sts.amazonaws.com"
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  ]

  tags = {
    Name = "${var.workspace}-eks"
  }
}
