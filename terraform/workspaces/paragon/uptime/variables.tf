variable "uptime_api_token" {
  description = "API Token for setting up BetterStack Uptime monitors."
  type        = string
  default     = null
}

variable "uptime_company" {
  description = "The pretty company name to include in BetterStack Uptime monitors."
  type        = string
}

variable "microservices" {
  description = "The microservices to create monitors for."
  type        = map(any)
}

locals {
  enabled = var.uptime_api_token != null
}
