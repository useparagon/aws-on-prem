data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster.name
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  token      = var.aws_session_token
  region     = var.aws_region
  default_tags {
    tags = {
      Creator     = "Terraform"
      Environment = var.environment
      Name        = "${var.workspace}-bastion"
      Workspace   = var.workspace
    }
  }
}

provider "kubernetes" {
  host                   = var.eks_cluster.cluster_endpoint
  token                  = var.eks_cluster_token
  cluster_ca_certificate = base64decode(var.eks_cluster.cluster_certificate_authority_data)
}
