output "eks_cluster" {
  value = {
    name                               = "${var.workspace}"
    arn                                = module.eks.cluster_arn
    id                                 = module.eks.cluster_id
    sg_id                              = module.eks.cluster_primary_security_group_id
    oidc_provider_arn                  = module.eks.oidc_provider_arn
    cluster_oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
    cluster_endpoint                   = module.eks.cluster_endpoint
    cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  }
}

output "cluster_super_admin" {
  value = {
    arn  = aws_iam_role.super_admin.arn
    id   = aws_iam_role.super_admin.id
    name = aws_iam_role.super_admin.name
  }
}

output "eks_super_admin" {
  value = {
    arn  = aws_iam_role.super_admin.arn
    name = aws_iam_role.super_admin.name
  }
}

output "eks" {
  value = module.eks
}
