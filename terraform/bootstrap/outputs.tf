# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

output "project_id" {
  value       = google_project.infrastructure.project_id
  description = "GCP project ID for this repository's infrastructure"
  sensitive   = false
}

output "project_number" {
  value       = google_project.infrastructure.number
  description = "GCP project number, needed to build principalSet identifiers"
  sensitive   = false
}

output "state_bucket" {
  value       = data.google_storage_bucket.bootstrap_state.name
  description = "GCS bucket holding this layer's Terraform state"
  sensitive   = false
}

output "workload_identity_provider" {
  value       = local.published_outputs.workload_identity_provider
  description = "GitHub WIF provider, for google-github-actions/auth's workload_identity_provider input"
  sensitive   = false
}

output "github_deployer_ro_email" {
  value       = local.published_outputs.github_deployer_ro_email
  description = "Email of the read-only deployer service account (terraform plan)"
  sensitive   = false
}

output "github_deployer_rw_email" {
  value       = local.published_outputs.github_deployer_rw_email
  description = "Email of the read-write deployer service account (terraform apply)"
  sensitive   = false
}

output "cloudflare_name_servers" {
  value       = cloudflare_zone.dungeon_studio.name_servers
  description = "Nameservers Cloudflare assigned dungeon.studio, to set at the registrar on cutover"
  sensitive   = false
}

output "cloudflare_ds_record" {
  value = {
    key_tag     = cloudflare_zone_dnssec.dungeon_studio.key_tag
    algorithm   = cloudflare_zone_dnssec.dungeon_studio.algorithm
    digest_type = cloudflare_zone_dnssec.dungeon_studio.digest_type
    digest      = cloudflare_zone_dnssec.dungeon_studio.digest
  }
  description = "DS record fields for dungeon.studio, to enter at the registrar"
  sensitive   = false
}
