output "bucket" {
  value = var.enabled ? module.bastion[0].bucket_name : ""
}

output "connection" {
  value = {
    bastion_dns = var.cloudflare_tunnel_enabled ? local.tunnel_domain : (var.enabled ? module.bastion[0].elb_ip : "")
    private_key = var.enabled ? tls_private_key.bastion[0].private_key_pem : ""
  }
}

output "security_group" {
  value = {
    host    = var.enabled ? module.bastion[0].bastion_host_security_group : []
    private = var.enabled ? module.bastion[0].private_instances_security_group : ""
  }
}

output "bastion_role_arn" {
  value = var.enabled ? data.aws_iam_role.bastion[0].arn : ""
}
