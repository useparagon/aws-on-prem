variable "aws_region" {
  description = "The AWS region resources are created in."
  type        = string
}

variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "docker_registry_server" {
  description = "EKS cluster auth token"
  default     = "docker.io"
}

variable "docker_username" {
  description = "Docker username to pull images."
  type        = string
}

variable "docker_password" {
  description = "Docker password to pull images."
  type        = string
}

variable "docker_email" {
  description = "Docker password to pull images."
  type        = string
}

variable "helm_values" {
  description = "Object containing values values to pass to the helm chart."
  type = object({
    subchart = map(object({
      enabled = bool
    }))
    global = object({
      env = map(string)
    })
  })
  sensitive = true
}

variable "acm_certificate_arn" {
  description = "The ARN of domain certificate."
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
