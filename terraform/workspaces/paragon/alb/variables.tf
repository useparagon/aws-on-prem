variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "domain" {
  description = "The root domain used for the microservices."
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

variable "release_ingress" {
  description = "The helm release for the ingress."
}

variable "release_paragon_on_prem" {
  description = "The helm release for the Paragon microservices."
}