# Migration: Move EKS addons from module-managed to standalone resources
# This allows for more granular control over addon versions and configuration

# Move coredns addon from module to standalone resource
moved {
  from = module.eks.aws_eks_addon.this["coredns"]
  to   = aws_eks_addon.addons["coredns"]
}

# Move kube-proxy addon from module to standalone resource
moved {
  from = module.eks.aws_eks_addon.this["kube-proxy"]
  to   = aws_eks_addon.addons["kube-proxy"]
}

# Move vpc-cni addon from module to standalone resource
moved {
  from = module.eks.aws_eks_addon.this["vpc-cni"]
  to   = aws_eks_addon.addons["vpc-cni"]
}
