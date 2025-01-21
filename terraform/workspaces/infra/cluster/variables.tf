variable "workspace" {
  description = "The name of the workspace resources are being created in."
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production, enterprise)."
}

variable "aws_region" {
  description = "The AWS region resources are created in."
}

variable "aws_access_key_id" {
  description = "AWS Access Key for AWS account to provision resources on."
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for AWS account to provision resources on."
}

variable "aws_session_token" {
  description = "AWS session token."
}

variable "vpc" {
  description = "The VPC to create resources in."
}

variable "public_subnet" {
  description = "The public subnets within the VPC."
}

variable "private_subnet" {
  description = "The private subnets within the VPC."
}

variable "bastion_role_arn" {
  description = "IAM role arn of bastion instance"
}

variable "eks_addon_ebs_csi_driver_enabled" {
  # Should be on for Kubernetes >= 1.23, but optional for backwards compatability for manually migrated installations.
  description = "Whether or not to enable AWS CSI Driver addon."
  type        = bool
}

variable "eks_admin_user_arns" {
  description = "List of ARNs for IAM users that should have admin access to cluster. Used for viewing cluster resources in AWS dashboard."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "eks_admin_role_arns" {
  description = "Comma-separated list of ARNs for IAM roles that should have admin access to cluster. Used for viewing cluster resources in AWS dashboard."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "k8_version" {
  description = "The version of Kubernetes to run in the cluster."
  type        = string
}

variable "k8_ondemand_node_instance_type" {
  description = "The compute instance type to use for Kubernetes nodes."
  type        = list(string)
}

variable "k8_spot_node_instance_type" {
  description = "The compute instance type to use for Kubernetes spot nodes."
  type        = list(string)
}

variable "k8_spot_instance_percent" {
  description = "The percentage of spot instances to use for Kubernetes nodes."
  type        = number
}

variable "k8_min_node_count" {
  description = "The minimum number of nodes to run in the Kubernetes cluster."
  type        = number
}

variable "k8_max_node_count" {
  description = "The maximum number of nodes to run in the Kubernetes cluster."
  type        = number
}

variable "kms_admin_role" {
  description = "ARN of IAM role allowed to administer KMS keys."
  type        = string
  default     = null
}

variable "create_autoscaling_linked_role" {
  description = "Whether or not to create an IAM role for autoscaling."
  type        = bool
}

locals {
  node_volume_size = 50

  nodes = {
    for key, value in {
      ondemand = var.k8_spot_instance_percent == 100 ? null : {
        min_count      = ceil(var.k8_min_node_count * (1 - (var.k8_spot_instance_percent / 100)))
        max_count      = ceil(var.k8_max_node_count * (1 - (var.k8_spot_instance_percent / 100)))
        instance_types = var.k8_ondemand_node_instance_type
        capacity       = "ON_DEMAND"
      }
      spot = var.k8_spot_instance_percent == 0 ? null : {
        min_count      = floor(var.k8_min_node_count * (var.k8_spot_instance_percent / 100))
        max_count      = ceil(var.k8_max_node_count * (var.k8_spot_instance_percent / 100))
        instance_types = var.k8_spot_node_instance_type
        capacity       = "SPOT"
      }
    } : key => value
    if value != null
  }

  # We need to lookup K8s taint effect from the AWS API value
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  cluster_autoscaler_label_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for label_name, label_value in coalesce(group.node_group_labels, {}) : "${name}|label|${label_name}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  cluster_autoscaler_taint_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for taint in coalesce(group.node_group_taints, []) : "${name}|taint|${taint.key}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
        value             = "${taint.value}:${local.taint_effects[taint.effect]}"
      }
    }
  ]...)

  cluster_autoscaler_asg_tags = merge(local.cluster_autoscaler_label_tags, local.cluster_autoscaler_taint_tags)

  node_security_group_rules = {
    egress_cluster_443 = {
      description                   = "Node groups to cluster API"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "egress"
      source_cluster_security_group = true
    }
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    egress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "Node to node CoreDNS"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    egress_self_coredns_udp = {
      description = "Node to node CoreDNS"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    egress_https = {
      description      = "Egress all HTTPS to internet"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
    }
    egress_ntp_tcp = {
      description      = "Egress NTP/TCP to internet"
      protocol         = "tcp"
      from_port        = 123
      to_port          = 123
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
    }
    egress_ntp_udp = {
      description      = "Egress NTP/UDP to internet"
      protocol         = "udp"
      from_port        = 123
      to_port          = 123
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
    }
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}
