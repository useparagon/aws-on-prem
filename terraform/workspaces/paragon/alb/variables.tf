variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "domain" {
  description = "The root domain used for the microservices."
  type        = string
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN of an existing certificate to use with the load balancer."
  type        = string
}

variable "microservices" {
  description = "The microservices running within the system."
  type = map(object({
    port             = number
    healthcheck_path = string
    public_url       = string
  }))
}

variable "public_monitors" {
  description = "The monitors running within the system exposed to the load balancer"
  type = map(object({
    port       = number
    public_url = string
  }))
}

variable "release_ingress" {
  description = "The helm release for the ingress."
}

variable "release_paragon_on_prem" {
  description = "The helm release for the Paragon microservices."
}
