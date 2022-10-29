output "nameservers" {
  description = "The nameservers for the Route53 zone."
  value       = module.alb.nameservers
}