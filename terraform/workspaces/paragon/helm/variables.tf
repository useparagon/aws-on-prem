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

variable "feature_flags_content" {
  description = "Optional YAML content for feature flags when not using a git repository."
  type        = string
  default     = null
}

variable "flipt_options" {
  description = "Map of flipt configuration variables"
  type        = map(any)
  sensitive   = true
}

variable "docker_registry_server" {
  description = "Docker container registry server."
  type        = string
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
  description = "Docker email to pull images."
  type        = string
}

variable "openobserve_email" {
  description = "OpenObserve admin login email."
  type        = string
  default     = null
}

variable "openobserve_password" {
  description = "OpenObserve admin login password."
  type        = string
  default     = null
}

variable "logs_bucket" {
  description = "Bucket to store system logs."
  type        = string
}

variable "helm_values" {
  description = "Object containing values to pass to the helm chart."
  type        = any
  sensitive   = true
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

variable "public_microservices" {
  description = "The microservices running within the system exposed to the load balancer"
  type = map(object({
    port             = number
    healthcheck_path = string
    public_url       = string
  }))
}

variable "monitors_enabled" {
  description = "Specifies that monitors are enabled."
  type        = bool
}

variable "monitor_version" {
  description = "The version of the monitors to install."
  type        = string
}

variable "monitors" {
  description = "The monitors running within the system."
  type = map(object({
    port       = number
    public_url = string
  }))
}

variable "public_monitors" {
  description = "The monitors running within the system exposed to the load balancer"
  type = map(object({
    port       = number
    public_url = string
  }))
}

variable "ingress_scheme" {
  description = "Whether the load balancer is 'internet-facing' (public) or 'internal' (private)"
  type        = string
}

variable "k8_version" {
  description = "The version of Kubernetes to run in the cluster."
  type        = string
}

variable "managed_sync_enabled" {
  description = "Whether to enable managed sync."
  type        = bool
}

variable "managed_sync_version" {
  description = "The version of the Managed Sync helm chart to install."
  type        = string
}
