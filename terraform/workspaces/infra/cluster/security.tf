data "aws_caller_identity" "current" {}

resource "aws_iam_role" "super_admin" {
  name = "${var.workspace}-eks-super-admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowBastionAssumeSuperAdmin"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workspace}-bastion"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.workspace}-eks-super-admin"
  }
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
