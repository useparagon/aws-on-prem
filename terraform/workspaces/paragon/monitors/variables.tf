variable "aws_workspace" {
  description = "The name of the resource group that all resources are associated with."
  type        = string
}

variable "grafana_aws_access_key_id" {
  description = "AWS access key id for Grafana. Optional and can be provisioned outside of Terraform."
  type        = string
  default     = null
}

variable "grafana_aws_secret_access_key" {
  description = "AWS secret access key for Grafana. Optional and can be provisioned outside of Terraform."
  type        = string
  default     = null
}

variable "grafana_admin_email" {
  description = "Grafana admin login email."
  type        = string
  default     = null
}

variable "grafana_admin_password" {
  description = "Grafana admin login password."
  type        = string
  default     = null
}

variable "grafana_customer_webhook_url" {
  description = "The webhook URL for customer notifications in Grafana."
  type        = string
  default     = null
}

variable "grafana_customer_defined_alerts_webhook_url" {
  description = "The webhook URL for customer-defined alerts in Grafana."
  type        = string
  default     = null
}

variable "pgadmin_admin_email" {
  description = "PGAdmin admin login email."
  type        = string
  default     = null
}

variable "pgadmin_admin_password" {
  description = "PGAdmin admin login password."
  type        = string
  default     = null
}
