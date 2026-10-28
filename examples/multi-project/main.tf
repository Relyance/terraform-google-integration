# Example: one service account scanning multiple GCP projects.
# The SA is created in the primary project; the scan roles are bound in every project.

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
  project = "acme-primary"
  region  = "us-central1"
}

module "relyance" {
  source = "../.."

  project_id  = "acme-primary"
  tenant_name = "acme"

  additional_project_ids = [
    "acme-analytics",
    "acme-prod-data",
  ]
}

output "paste_into_relyance_ui" {
  value = module.relyance.relyance_form_values
}
