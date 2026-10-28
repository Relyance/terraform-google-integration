# Example: single GCP project, standard prod environment.

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
  project = "my-gcp-project"
  region  = "us-central1"
}

module "relyance" {
  source = "../.."

  project_id  = "my-gcp-project"
  tenant_name = "acme"

  # relyance_env defaults to "prod"; override to "prod-eu" for EU tenants.
}

output "paste_into_relyance_ui" {
  value = module.relyance.relyance_form_values
}
