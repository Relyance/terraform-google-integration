output "service_account_email" {
  description = "Email of the created service account. Enter this in the Relyance UI (Service Account Email field)."
  value       = google_service_account.this.email
}

output "project_ids" {
  description = "Comma-separated list of all scanned project IDs. Enter this in the Relyance UI (Project IDs field)."
  value       = join(",", concat([var.project_id], var.additional_project_ids))
}

output "relyance_form_values" {
  description = <<-EOT
    Values to enter in the Relyance UI. `inventory` covers the project/org
    scan form; one entry per enabled data integration follows, matching that
    integration's Direct Connection form (service account email + the
    project IDs you may use as "Project ID to scan").
  EOT
  value = merge(
    {
      inventory = {
        service_account_email = google_service_account.this.email
        project_ids           = join(",", local.all_project_ids)
      }
    },
    {
      for key in keys(local.enabled_integrations) : key => {
        service_account_email = google_service_account.this.email
        project_ids           = join(",", local.all_project_ids)
      }
    }
  )
}
