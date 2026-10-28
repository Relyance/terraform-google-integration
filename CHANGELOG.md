# Changelog

## v1.2.0

Three additional read-only scan roles, and a repaired release artifact.

- **Adds `roles/bigtable.viewer`, `roles/composer.viewer`, `roles/datastore.viewer`**
  to the per-project scan roles, so BigTable, Cloud Composer, and Firestore metadata
  are discoverable. `google_project_iam_member` bindings go from 4 to 7 per scanned
  project.
- **`modules/org-scan`** picks up the same three plus `roles/cloudapiregistry.viewer`,
  bringing the org-level role set in line with the single-project module.
- **Fixes the published v1.1.0 archive.** The v1.1.0 `module.zip` on
  `assets.relyance.ai` was packaged incorrectly: every file sat under a nested
  `module/` directory, so `terraform init` found no Terraform files at the archive
  root, and the accompanying `SHA256SUMS` listed a digest that did not match the
  shipped zip. **If you pinned `version = "1.1.0"`, move to `1.2.0`** — 1.1.0 cannot
  be initialized.

## v1.1.0

Initial customer-preview release.

- Single-project and multi-project module: creates a customer service account that
  Relyance's scanner impersonates via `roles/iam.workloadIdentityUser`, and binds
  read-only scan roles (`roles/iam.securityAuditor`, `roles/aiplatform.viewer`,
  `roles/cloudfunctions.viewer`, `roles/cloudapiregistry.viewer`) in the primary
  project and every `additional_project_ids` entry.
- Organization-wide module (`modules/org-scan`): binds `roles/cloudasset.viewer` and
  `roles/browser` at the org level to drive the org-wide asset crawl.
- Per-integration data-scan roles enabled through the `integrations` map, generated
  from the Relyance SDK's declared permissions and committed as
  `generated/permissions.json`.

> The published v1.1.0 archive is malformed — see v1.2.0 above.
