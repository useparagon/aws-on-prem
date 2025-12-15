locals {
  cluster_addons = merge(
    {
      coredns = {
        version = "v1.11.4-eksbuild.14"
      }
      kube-proxy = {
        version = "v1.31.10-eksbuild.2"
      }
      vpc-cni = {
        version = "v1.19.6-eksbuild.7"
      }
    },
    var.eks_addon_ebs_csi_driver_enabled ? {
      aws-ebs-csi-driver = {
        version = "v1.45.0-eksbuild.2"
      }
    } : {}
  )
}

resource "aws_eks_addon" "addons" {
  for_each = local.cluster_addons

  addon_name        = each.key
  addon_version     = try(each.value.version, null)
  cluster_name      = module.eks.cluster_name
  resolve_conflicts = "OVERWRITE"

  # EBS CSI driver requires a service account role ARN
  service_account_role_arn = each.key == "aws-ebs-csi-driver" && var.eks_addon_ebs_csi_driver_enabled ? module.aws_ebs_csi_driver_iam_role[0].iam_role_arn : null

  # tags = {
  #   Name = "${var.workspace}-eks"
  # }

  # certain addons such as coredns and EBS CSI require nodes
  depends_on = [
    module.eks_managed_node_group
  ]
}
