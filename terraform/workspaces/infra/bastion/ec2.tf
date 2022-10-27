# Get the list of official Canonical Ubuntu 16.04 AMIs
data "aws_ami" "ubuntu-1604" {
  most_recent = true

  filter {
    name = "name"
    # TODO:  upgrade to ubuntu 20.xx
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "startup" {
  template = file("${path.module}/../templates/bastion/bastion-startup.tpl.sh")
  vars = {
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id
    cluster_name   = var.eks_cluster.name
    bastion_role   = local.resource_group
  }
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "bastion" {
  key_name   = "${local.resource_group}-key"
  public_key = tls_private_key.bastion.public_key_openssh

  tags = {
    Name = "${local.resource_group}-key-pair"
  }
}

resource "random_string" "bastion_id" {
  length  = 4
  special = false
  number  = false
  lower   = true
  upper   = true
}

module "bastion" {
  source  = "Guimove/bastion/aws"
  version = "2.2.4"

  bucket_name     = local.resource_group
  log_expiry_days = 365

  allow_ssh_commands         = true
  region                     = var.aws_region
  vpc_id                     = var.vpc_id
  elb_subnets                = var.public_subnet.*.id
  auto_scaling_group_subnets = var.private_subnet.*.id
  is_lb_private              = "false"
  create_dns_record          = "false"

  private_ssh_port = local.ssh_port
  public_ssh_port  = local.ssh_port
  cidrs            = var.ssh_whitelist

  bastion_ami                  = data.aws_ami.ubuntu-1604.id
  bastion_host_key_pair        = aws_key_pair.bastion.id
  instance_type                = "t3.nano"
  bastion_iam_policy_name      = local.resource_group
  bastion_iam_role_name        = local.resource_group
  bastion_launch_template_name = "paragon-bastion-${random_string.bastion_id.result}" # 32 character limit for `name_prefix` arguments, like load balancer and iam_policy
  extra_user_data_content      = data.template_file.startup.rendered
}
