# Example: org-wide GCP scan — discovers all resources across the entire GCP organization.
# The SA is created in sa_project_id; roles are bound at the organization level.

terraform {
  required_version = ">= 1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "google" {
  project = "acme-platform"
  region  = "us-central1"
}

module "relyance_gcp_org" {
  source = "../../modules/org-scan"

  sa_project_id   = "acme-platform"
  organization_id = "897656485184"
  tenant_name     = "acme"

  # relyance_env defaults to "prod"; override to "prod-eu" for EU tenants.
}

output "paste_into_relyance_ui" {
  value = module.relyance_gcp_org.relyance_form_values
}
