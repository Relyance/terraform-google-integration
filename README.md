# Relyance GCP Integration — Terraform Module

Terraform that grants Relyance the **least-privilege, read-only** access needed to run Relyance GCP Cloud Scan integrations.

The module creates a GCP service account in your project, binds the required read-only roles, and grants the Relyance scanner service account permission to impersonate it via short-lived tokens. You do not create or share long-lived credential files with Relyance.

## Quick start: cloud inventory in one project

```hcl
module "relyance_gcp" {
  source  = "Relyance/integration/google"
  version = "1.2.0"

  project_id  = "my-gcp-project"
  tenant_name = "acme"
}

output "relyance_setup_values" {
  value = module.relyance_gcp.relyance_form_values
}
```

```bash
terraform init
terraform plan
terraform apply
terraform output -json relyance_setup_values
```

`relyance_setup_values` returns the two values to enter into the Relyance UI:

```hcl
relyance_form_values = {
  inventory = {
    service_account_email = "rely-acme-int@my-gcp-project.iam.gserviceaccount.com"
    project_ids           = "my-gcp-project"
  }
}
```

## Scanning multiple projects

Pass the additional project IDs to `additional_project_ids`. The service account is created in `project_id`; the scan roles are bound in the primary project **and** each additional project.

```hcl
module "relyance_gcp" {
  source  = "Relyance/integration/google"
  version = "1.2.0"

  project_id  = "acme-primary"
  tenant_name = "acme"

  additional_project_ids = [
    "acme-analytics",
    "acme-prod-data",
  ]
}
```

## EU tenants

Set `relyance_env = "prod-eu"` to point impersonation at the EU Relyance scanner:

```hcl
module "relyance_gcp" {
  source  = "Relyance/integration/google"
  version = "1.2.0"

  project_id   = "my-gcp-project"
  tenant_name  = "acme"
  relyance_env = "prod-eu"
}
```

## What is created

| Resource | Purpose |
|---|---|
| `google_service_account` | Customer SA Relyance impersonates to scan |
| `google_project_iam_member` × 7 | Read-only scan roles in every scanned project |
| `google_service_account_iam_member` | Grants Relyance's scanner SA `roles/iam.workloadIdentityUser` on the created SA |

### Roles bound

| Role | Why |
|---|---|
| `roles/iam.securityAuditor` | Broad read-only access to IAM, resource metadata, and security configuration |
| `roles/aiplatform.viewer` | Agent Platform (Vertex AI) resources |
| `roles/cloudfunctions.viewer` | Cloud Functions metadata |
| `roles/cloudapiregistry.viewer` | Cloud API Registry (Beta) |
| `roles/bigtable.viewer` | BigTable metadata |
| `roles/composer.viewer` | Cloud Composer metadata |
| `roles/datastore.viewer` | Firestore metadata |

## Optional data-content integrations

Enable data-scan access per integration with the `integrations` map; each key binds that integration's read-only roles (generated from the Relyance SDK's declared permissions — see `generated/permissions.json`) in the primary project and every `additional_project_ids` entry.

```hcl
integrations = {
  gcloud_storage  = {}   # + roles/storage.objectViewer
  gcloud_bigquery = {}   # + roles/bigquery.dataViewer, roles/bigquery.jobUser
  gcloud_spanner  = {}   # + roles/spanner.databaseReader, roles/spanner.viewer
  gcloud_bigtable = {}   # + roles/bigtable.reader
}
```

| Integration | Added roles | Notes |
|---|---|---|
| `gcloud_storage` | `roles/storage.objectViewer` | bucket metadata/list already covered by `roles/iam.securityAuditor` |
| `gcloud_bigquery` | `roles/bigquery.dataViewer`, `roles/bigquery.jobUser` | `dataViewer` includes `tables.getData`, required by the scanner's query path |
| `gcloud_spanner` | `roles/spanner.databaseReader`, `roles/spanner.viewer` | |
| `gcloud_bigtable` | `roles/bigtable.reader` | |

Scoping (which buckets/datasets/instances get scanned) is configured in the Relyance integration form, not in IAM — the scanner needs project-level list permissions per the SDK's declared requirements.

`gcloud_operations` (Cloud Trace) is not supported: it has no keyless impersonation auth form in the Relyance SDK yet.

After `terraform apply`, `relyance_form_values` prints one entry per enabled integration with the values for that integration's Direct Connection form.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_id` | string | required | Primary GCP project ID |
| `tenant_name` | string | required | Short tenant identifier (used in SA name) |
| `suffix` | string | `""` | Optional suffix appended to the SA name |
| `relyance_env` | string | `"prod"` | `"prod"` or `"prod-eu"` |
| `additional_project_ids` | list(string) | `[]` | Extra projects to grant scan roles in |
| `integrations` | map(object) | `{}` | Data integrations to enable; see Data integrations section |

## Outputs

| Output | Description |
|---|---|
| `relyance_form_values` | Map of form values: `inventory` plus one entry per enabled integration, each `{ service_account_email, project_ids }` |
| `service_account_email` | Email of the created service account |
| `project_ids` | Comma-separated scanned project IDs |

## How authentication works

Relyance never receives a key file. The Relyance scanner service account
(`tenant-gcp-integrations@relyance-<env>.iam.gserviceaccount.com`) calls the
IAM `generateAccessToken` API to obtain short-lived tokens impersonating the
customer SA, which is the standard GCP workload impersonation pattern.

## Terraform and OpenTofu

The same module works with Terraform and OpenTofu. Public CI validates the module,
examples and inventory plan tests with both CLIs. Use the matching `init`, `plan`
and `apply` commands. Review the plan before applying IAM changes.

Existing installations may continue using the original
`assets.relyance.ai/relyance/integration/gcp` address. When changing the
source of an existing module, retain its module block name, inputs and version,
then review the plan; changing the source does not require renaming resources.

## License and releases

[MPL-2.0](LICENSE). Releases are immutable; fixes receive a new version.
`PUBLIC_RELEASE.json` records the reviewed source revision and exported file hashes.

Report issues in this public repository. Permission catalogs are generated and
reviewed upstream; edits to generated JSON alone are not a supported update path.
