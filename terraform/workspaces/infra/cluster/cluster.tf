# Creating the EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.24.1"

  cluster_name    = var.workspace
  cluster_version = "1.23"
  subnet_ids      = var.private_subnet.*.id

  vpc_id                    = var.vpc.id
  create_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = aws_iam_role.super_admin.arn,
      username = aws_iam_role.super_admin.name,
      groups   = ["system:masters"]
    },
    {
      rolearn  = var.bastion_role_arn
      username = "system:node:{{EC2PrivateDNSName}}",
      groups   = ["system:masters"]
    }
  ]
}

resource "aws_iam_role" "node_role" {
  name               = "${var.workspace}-eks-node-role"
  description        = "role for eks node group"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "eks_worker_policy" {
  name        = "${var.workspace}-eks-worker-policy"
  description = "Worker policy for the ALB Ingress."
  policy      = file("./templates/eks/eks-worker-policy.tpl.json")

  tags = {
    Name = "${var.workspace}-eks-worker-policy"
  }
}

resource "aws_iam_policy_attachment" "custom_worker_policy_attachment" {
  name       = "${var.workspace}-custom-worker-policy"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = aws_iam_policy.eks_worker_policy.arn
}

resource "aws_iam_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  name       = "${var.workspace}-eks-worker-node-policy"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  name       = "${var.workspace}-ec2-container-registry-policy"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy_attachment" "AmazonEKS_CNI_Policy" {
  name       = "${var.workspace}-eks-cni-policy"
  roles      = [aws_iam_role.node_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

module "eks_node_group" {
  source = "cloudposse/eks-node-group/aws"
  # Cloud Posse recommends pinning every module to a specific version
  version = "0.25.0"

  instance_types             = ["t3a.xlarge"]
  subnet_ids                 = var.private_subnet.*.id
  min_size                   = 1
  max_size                   = 10 # TODO: allow configuring max size, decrease size
  desired_size               = 3  # TODO: decrease desired size
  cluster_name               = var.workspace
  create_before_destroy      = true
  kubernetes_version         = ["1.22"]
  namespace                  = "paragon"
  node_role_arn              = [aws_iam_role.node_role.arn]
  cluster_autoscaler_enabled = true

  depends_on = [
    module.eks,
    aws_iam_role.node_role,
    aws_iam_policy_attachment.custom_worker_policy_attachment,
    aws_iam_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

# Create EKS cluster node group

