# Move aws-ebs-csi-driver addon from standalone resource with count to for_each map
moved {
  from = aws_eks_addon.aws_ebs_csi_driver[0]
  to   = aws_eks_addon.addons["aws-ebs-csi-driver"]
}
