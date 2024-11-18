resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}

locals {
  key_administrators = distinct(concat(
    compact([for user in var.eks_admin_user_arns : user.userarn if user != null]),
    [var.kms_admin_role != null ? var.kms_admin_role : data.aws_caller_identity.current.arn]
  ))
}

########################################
# EBS KMS Key
########################################
module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description             = "${var.workspace} ebs encryption key"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  aliases_use_name_prefix = false

  key_administrators = local.key_administrators

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    aws_iam_service_linked_role.autoscaling.arn,
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]
  computed_aliases = {
    ebs = { name = "eks/${var.workspace}/ebs" }
  }
}

########################################
# Secrets KMS Key
########################################
module "cluster_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description             = "${var.workspace} cluster encryption key"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  aliases_use_name_prefix = false

  key_administrators = local.key_administrators

  key_users = [
    module.eks.cluster_iam_role_arn
  ]
  computed_aliases = {
    cluster = { name = "eks/${var.workspace}/cluster" }
  }
}
