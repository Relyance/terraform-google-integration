# Inventory scan plus two data integrations (GCS + BigQuery) on one
# service account. Enable more integrations by adding their keys.

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
  project = "my-data-project"
  region  = "us-central1"
}

module "relyance_gcp" {
  source = "../.."

  project_id  = "my-data-project"
  tenant_name = "acme"

  integrations = {
    gcloud_storage  = {}
    gcloud_bigquery = {}
    # gcloud_spanner  = {}
    # gcloud_bigtable = {}
  }
}

output "relyance_form_values" {
  value = module.relyance_gcp.relyance_form_values
}
