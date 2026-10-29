# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# terraform/infrastructure/ reads these values here because the deployers
# cannot read this layer's state, which terraform_remote_state needs. Plan on
# any pull request can read this object, so publish only non-secret values.
locals {
  published_outputs = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.github.name
    github_deployer_ro_email   = google_service_account.github_deployer_ro.email
    github_deployer_rw_email   = google_service_account.github_deployer_rw.email
    grafana_stack_url          = data.grafana_cloud_stack.this.url
    grafana_stack_id           = data.grafana_cloud_stack.this.id
    grafana_otlp_url           = data.grafana_cloud_stack.this.otlp_url
    grafana_gcp_reader_email   = google_service_account.grafana_gcp_reader.email
    cloudflare_zone_id         = cloudflare_zone.dungeon_studio.id
    privacy_email_destination  = cloudflare_email_routing_address.privacy.email
  }
}

resource "google_storage_bucket_object" "published_outputs" {
  bucket       = google_storage_bucket.infrastructure_state.name
  name         = "bootstrap-outputs.json"
  content_type = "application/json"
  content      = jsonencode(local.published_outputs)
}
