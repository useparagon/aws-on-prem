data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# reference to load balancer created by k8 ingress
data "aws_lb" "load_balancer" {
  name = var.aws_workspace

  # requires ingress for the controller and then logging/on-prem to deploy pods that trigger LB creation
  depends_on = [
    helm_release.ingress,
    helm_release.paragon_logging,
    helm_release.paragon_on_prem,
  ]
}
