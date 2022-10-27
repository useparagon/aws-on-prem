provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token
  region     = var.aws_region
  default_tags {
    tags = {
      Creator     = "Terraform"
      Environment = var.environment
      Name        = "${var.workspace}-eks"
      Workspace   = var.workspace
    }
  }
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = var.workspace
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.eks_cluster.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}
