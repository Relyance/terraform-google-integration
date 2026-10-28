locals {
  sa_account_id = var.suffix != "" ? "rely-${var.tenant_name}-int-${var.suffix}" : "rely-${var.tenant_name}-int"

  # Relyance scanner SA that impersonates the customer SA we create.
  relyance_scanner_sa = "tenant-gcp-integrations@relyance-${var.relyance_env}.iam.gserviceaccount.com"

  # Roles bound at the organization level. cloudasset.viewer + browser drive the
  # org-wide asset crawl; the remaining roles power downstream per-resource crawlers.
  org_roles = toset([
    "roles/cloudasset.viewer",       # Discovers all resources across the org
    "roles/browser",                 # Lists projects and folders across the org
    "roles/iam.securityAuditor",     # Security metadata for downstream crawlers
    "roles/aiplatform.viewer",       # Agent Platform resources
    "roles/cloudfunctions.viewer",   # Cloud Functions metadata
    "roles/cloudapiregistry.viewer", # Cloud API Registry Viewer (Beta)
    "roles/bigtable.viewer",         # BigTable metadata
    "roles/composer.viewer",         # Cloud Composer metadata
    "roles/datastore.viewer",        # Firestore metadata
  ])
}

resource "google_service_account" "this" {
  project      = var.sa_project_id
  account_id   = local.sa_account_id
  display_name = "Relyance org scanner — ${var.tenant_name}"
}

# All roles are bound at the organization level so the SA can discover every
# project and resource across the org via the Cloud Asset Inventory API.
resource "google_organization_iam_member" "org_roles" {
  for_each = local.org_roles

  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${google_service_account.this.email}"
}

# Allow the Relyance scanner SA to impersonate the customer SA via short-lived tokens.
resource "google_service_account_iam_member" "relyance_impersonation" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.relyance_scanner_sa}"
}
