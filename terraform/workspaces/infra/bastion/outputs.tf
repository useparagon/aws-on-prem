output "bucket" {
  value = module.bastion.bucket_name
}

output "load_balancer" {
  value = {
    private_key = tls_private_key.bastion.private_key_pem
    public_key  = tls_private_key.bastion.public_key_openssh
    public_dns  = module.bastion.elb_ip
  }
}

output "security_group" {
  value = {
    host    = module.bastion.bastion_host_security_group
    private = module.bastion.private_instances_security_group
  }
}

output "bastion_role_arn" {
  value = data.aws_iam_role.bastion.arn
}
