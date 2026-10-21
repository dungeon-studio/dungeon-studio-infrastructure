# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# terraform/infrastructure/ consumes a few of this layer's values, but the
# deployers hold no read on this layer's state, and terraform_remote_state
# would need it. Republish the non-secret values beside the infrastructure
# layer's state, which the deployers already read.
resource "google_storage_bucket_object" "published_outputs" {
  bucket       = google_storage_bucket.infrastructure_state.name
  name         = "bootstrap-outputs.json"
  content_type = "application/json"
  content = jsonencode({
    workload_identity_provider = google_iam_workload_identity_pool_provider.github.name
    github_deployer_ro_email   = google_service_account.github_deployer_ro.email
    github_deployer_rw_email   = google_service_account.github_deployer_rw.email
  })
}
