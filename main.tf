locals {
  sa_account_id = var.suffix != "" ? "rely-${var.tenant_name}-int-${var.suffix}" : "rely-${var.tenant_name}-int"

  # Relyance scanner SA that impersonates the customer SA we create.
  relyance_scanner_sa = "tenant-gcp-integrations@relyance-${var.relyance_env}.iam.gserviceaccount.com"

  # Roles bound in every scanned project.
  scan_roles = toset([
    "roles/iam.securityAuditor",     # Security Auditor - broad read-only metadata
    "roles/aiplatform.viewer",       # Agent Platform Viewer
    "roles/cloudfunctions.viewer",   # Cloud Functions Viewer
    "roles/cloudapiregistry.viewer", # Cloud API Registry Viewer (Beta)
    "roles/bigtable.viewer",         # BigTable metadata
    "roles/composer.viewer",         # Cloud Composer metadata
    "roles/datastore.viewer",        # Firestore metadata
  ])

  all_project_ids = toset(concat([var.project_id], var.additional_project_ids))

  # One binding per (project, role) pair — stable string key for for_each.
  project_role_bindings = {
    for pair in setproduct(local.all_project_ids, local.scan_roles) :
    "${pair[0]}/${pair[1]}" => { project_id = pair[0], role = pair[1] }
  }

  # Data-scan catalog -- generated from the Relyance SDK auth configs by
  # scripts/generate_permissions.py (drift-gated in CI via make generate-check).
  # NB: var.integrations' validation allowlist must stay in sync with the
  # catalog keys; a key allowed there but missing here fails with an opaque
  # "Invalid index" at plan time.
  data_scan_catalog = jsondecode(file("${path.module}/generated/permissions.json")).integrations

  enabled_integrations = {
    for key, cfg in var.integrations : key => cfg if cfg.enabled
  }

  data_scan_roles = toset(flatten([
    for key in keys(local.enabled_integrations) : local.data_scan_catalog[key].roles
  ]))

  # One binding per (project, role) pair, disjoint from the inventory
  # scan_roles resource so enabling data scan never churns inventory bindings.
  data_role_bindings = {
    for pair in setproduct(local.all_project_ids, local.data_scan_roles) :
    "${pair[0]}/${pair[1]}" => { project_id = pair[0], role = pair[1] }
  }
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = local.sa_account_id
  display_name = "Relyance scanner — ${var.tenant_name}"
}

# Bind scan roles in the primary project and any additional projects.
resource "google_project_iam_member" "scan_roles" {
  for_each = local.project_role_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Bind per-integration data-scan roles in every scanned project.
resource "google_project_iam_member" "data_scan_roles" {
  for_each = local.data_role_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Allow the Relyance scanner SA to impersonate the customer SA via short-lived tokens.
# This is the GCP equivalent of the AWS cross-account AssumeRole trust policy.
resource "google_service_account_iam_member" "relyance_impersonation" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.relyance_scanner_sa}"
}
