# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

output "project_id" {
  value       = google_project.org.project_id
  description = "Org GCP project ID"
  sensitive   = false
}

output "project_number" {
  value       = google_project.org.number
  description = "Org GCP project number, needed to build principalSet identifiers"
  sensitive   = false
}

output "state_bucket" {
  value       = data.google_storage_bucket.state.name
  description = "GCS bucket holding Terraform state for every layer in this repository"
  sensitive   = false
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "GitHub WIF provider, for google-github-actions/auth's workload_identity_provider input"
  sensitive   = false
}

output "github_deployer_ro_email" {
  value       = google_service_account.github_deployer_ro.email
  description = "Email of the read-only deployer service account (terraform plan)"
  sensitive   = false
}

output "github_deployer_rw_email" {
  value       = google_service_account.github_deployer_rw.email
  description = "Email of the read-write deployer service account (terraform apply)"
  sensitive   = false
}
