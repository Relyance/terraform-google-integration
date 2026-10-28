variable "project_id" {
  description = "GCP project ID where the service account is created and primary scanning runs."
  type        = string
}

variable "tenant_name" {
  description = <<-EOT
    Short tenant identifier used in the service account name.
    The account ID becomes: rely-<tenant_name>-int[-<suffix>].
    Example: "dataeng", "acme".
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}[a-z0-9]$", var.tenant_name))
    error_message = "tenant_name must be 2-21 lowercase letters, digits, and hyphens; start and end with a letter or digit. When suffix is also set, tenant_name + suffix must be at most 20 chars combined (GCP caps the service account ID at 30)."
  }
}

variable "suffix" {
  description = <<-EOT
    Optional suffix appended to the service account name (rely-<tenant_name>-int-<suffix>).
    Useful when multiple integrations exist for the same tenant, e.g. "prod", "analytics".
    Leave empty (default) to omit the suffix.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.suffix == "" || can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.suffix))
    error_message = "suffix must be lowercase letters, digits, and hyphens when set, and must start and end with a letter or digit."
  }

  validation {
    condition     = length(var.suffix) == 0 || (length(var.suffix) + length(var.tenant_name) + 10) <= 30
    error_message = "rely-<tenant_name>-int-<suffix> would exceed 30 chars (GCP service account ID limit); tenant_name and suffix combined must be at most 20 chars."
  }
}

variable "relyance_env" {
  description = <<-EOT
    Relyance environment whose scanner service account is granted impersonation.
    "prod"    -> tenant-gcp-integrations@relyance-prod.iam.gserviceaccount.com
    "prod-eu" -> tenant-gcp-integrations@relyance-prod-eu.iam.gserviceaccount.com
  EOT
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "prod-eu", "uat"], var.relyance_env)
    error_message = "relyance_env must be \"prod\", \"prod-eu\", or \"uat\" (uat is for Relyance-internal testing only)."
  }
}

variable "additional_project_ids" {
  description = <<-EOT
    Additional GCP project IDs to scan with the same service account.
    The service account is created in var.project_id; the scan roles are bound
    in the primary project and in every project listed here.
  EOT
  type        = list(string)
  default     = []
}

variable "integrations" {
  description = <<-EOT
    GCP data integrations to enable for this service account, keyed by the
    Relyance integration key. Each enabled key binds that integration's
    read-only roles (see generated/permissions.json) in the primary project
    and every additional project. Default {} = inventory scanning only.

    Supported keys: gcloud_storage, gcloud_bigquery, gcloud_spanner,
    gcloud_bigtable. (gcloud_operations is not supported: it has no keyless
    impersonation auth form in the Relyance SDK yet.)
  EOT
  type = map(object({
    enabled = optional(bool, true)
  }))
  default = {}

  validation {
    condition = length(setsubtract(keys(var.integrations), [
      "gcloud_storage", "gcloud_bigquery", "gcloud_spanner", "gcloud_bigtable",
    ])) == 0
    error_message = "Unknown integration key. Supported keys: gcloud_storage, gcloud_bigquery, gcloud_spanner, gcloud_bigtable (gcloud_operations is key-auth-only in the SDK and unsupported)."
  }
}
