variable "sa_project_id" {
  description = "GCP project ID where the service account is created."
  type        = string
}

variable "organization_id" {
  description = <<-EOT
    10–12 digit GCP Organization ID. All roles are bound at this organization level,
    enabling the SA to discover resources across the entire org.
    Find it in GCP Console by selecting your Organization in the resource picker.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9]{10,12}$", var.organization_id))
    error_message = "organization_id must be a 10–12 digit numeric string (e.g. \"897656485184\")."
  }
}

variable "tenant_name" {
  description = <<-EOT
    Short tenant identifier used in the service account name.
    The account ID becomes: rely-<tenant_name>-int[-<suffix>].
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}[a-z0-9]$", var.tenant_name))
    error_message = "tenant_name must be 2-21 lowercase letters, digits, and hyphens; start and end with a letter or digit. When suffix is also set, tenant_name + suffix must be at most 20 chars combined (GCP caps the service account ID at 30)."
  }
}

variable "suffix" {
  description = "Optional suffix appended to the service account name."
  type        = string
  default     = ""

  validation {
    condition     = var.suffix == "" || can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.suffix))
    error_message = "suffix must be lowercase letters, digits, and hyphens when set."
  }

  validation {
    condition     = length(var.suffix) == 0 || (length(var.suffix) + length(var.tenant_name) + 10) <= 30
    error_message = "rely-<tenant_name>-int-<suffix> would exceed 30 chars (GCP service account ID limit); tenant_name and suffix combined must be at most 20 chars."
  }
}

variable "relyance_env" {
  description = "Relyance environment. \"prod\" or \"prod-eu\"."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "prod-eu", "uat"], var.relyance_env)
    error_message = "relyance_env must be \"prod\", \"prod-eu\", or \"uat\" (uat is for Relyance-internal testing only)."
  }
}

