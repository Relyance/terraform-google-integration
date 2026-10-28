mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/example-project/serviceAccounts/rely-example-int@example-project.iam.gserviceaccount.com"
      email = "rely-example-int@example-project.iam.gserviceaccount.com"
    }
  }
}

run "project_inventory_has_no_content_roles" {
  command = plan
  variables {
    project_id  = "example-project"
    tenant_name = "example"
  }
  assert {
    condition = toset([for binding in google_project_iam_member.scan_roles : binding.role]) == toset([
      "roles/iam.securityAuditor", "roles/aiplatform.viewer", "roles/cloudfunctions.viewer",
      "roles/cloudapiregistry.viewer", "roles/bigtable.viewer", "roles/composer.viewer", "roles/datastore.viewer",
    ])
    error_message = "Inventory must retain the reviewed seven-role metadata baseline."
  }
  assert {
    condition     = length(google_project_iam_member.data_scan_roles) == 0
    error_message = "Project inventory must not enable optional data-content roles."
  }
  assert {
    condition = (
      google_service_account_iam_member.relyance_impersonation.role == "roles/iam.workloadIdentityUser" &&
      google_service_account_iam_member.relyance_impersonation.member == "serviceAccount:tenant-gcp-integrations@relyance-prod.iam.gserviceaccount.com"
    )
    error_message = "Keyless impersonation must be restricted to the production scanner."
  }
}

run "eu_inventory_covers_all_requested_projects" {
  command = plan
  variables {
    project_id             = "example-primary"
    tenant_name            = "example"
    additional_project_ids = ["example-secondary"]
    relyance_env           = "prod-eu"
  }
  assert {
    condition     = length(google_project_iam_member.scan_roles) == 14
    error_message = "Both requested projects must receive the inventory roles."
  }
  assert {
    condition     = google_service_account_iam_member.relyance_impersonation.member == "serviceAccount:tenant-gcp-integrations@relyance-prod-eu.iam.gserviceaccount.com"
    error_message = "EU inventory must use the EU scanner identity."
  }
}

run "organization_inventory_has_no_project_content_roles" {
  command = plan
  module {
    source = "./modules/org-scan"
  }
  variables {
    sa_project_id   = "example-project"
    organization_id = "123456789012"
    tenant_name     = "example"
  }
  assert {
    condition = (
      length(google_organization_iam_member.org_roles) == 9 &&
      contains([for binding in google_organization_iam_member.org_roles : binding.role], "roles/cloudasset.viewer") &&
      contains([for binding in google_organization_iam_member.org_roles : binding.role], "roles/browser")
    )
    error_message = "Organization inventory must retain discovery across projects and folders."
  }
}
