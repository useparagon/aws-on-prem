terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.0"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.eks_cluster.cluster_endpoint
    token                  = var.eks_cluster_token
    cluster_ca_certificate = base64decode(var.eks_cluster.cluster_certificate_authority_data)
  }
}

provider "kubernetes" {
  host                   = var.eks_cluster.cluster_endpoint
  token                  = var.eks_cluster_token
  cluster_ca_certificate = base64decode(var.eks_cluster.cluster_certificate_authority_data)
}
