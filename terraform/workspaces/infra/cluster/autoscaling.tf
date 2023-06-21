resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_tags" {
  for_each = local.cluster_autoscaler_asg_tags

  autoscaling_group_name = each.value.autoscaling_group

  tag {
    key   = each.value.key
    value = each.value.value

    propagate_at_launch = false
  }
}

module "cluster_autoscaler" {
  source  = "lablabs/eks-cluster-autoscaler/aws"
  version = "2.1.0"

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  irsa_role_name_prefix            = "${var.workspace}-irsa"

  depends_on = [
    module.eks,
    module.eks_managed_node_group
  ]
}
