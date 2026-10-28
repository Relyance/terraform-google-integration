output "service_account_email" {
  description = "Email of the created service account. Enter this in the Relyance UI."
  value       = google_service_account.this.email
}

output "organization_id" {
  description = "The organization ID. Enter this in the Relyance UI (Organization ID field)."
  value       = var.organization_id
}

output "relyance_form_values" {
  description = <<-EOT
    Values to enter into the Relyance GCP Organization integration form:
      service_account_email — paste into the Service Account Email field.
      organization_id       — paste into the Organization ID field.
  EOT
  value = {
    service_account_email = google_service_account.this.email
    organization_id       = var.organization_id
  }
}
