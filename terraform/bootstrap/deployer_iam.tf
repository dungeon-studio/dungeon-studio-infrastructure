# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  deployers = {
    ro = {
      service_account_id = google_service_account.github_deployer_ro.name
      email              = google_service_account.github_deployer_ro.email
      state_bucket_role  = "roles/storage.objectViewer"
      principal          = local.wif_principal_any_ref
    }
    rw = {
      service_account_id = google_service_account.github_deployer_rw.name
      email              = google_service_account.github_deployer_rw.email
      state_bucket_role  = "roles/storage.objectAdmin"
      principal          = local.wif_principal_develop
    }
  }
}

resource "google_storage_bucket_iam_member" "deployer_state_objects" {
  for_each = local.deployers

  bucket = data.google_storage_bucket.state.name
  role   = each.value.state_bucket_role
  member = "serviceAccount:${each.value.email}"
}

resource "google_storage_bucket_iam_member" "deployer_state_bucket_reader" {
  for_each = local.deployers

  bucket = data.google_storage_bucket.state.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${each.value.email}"
}

# Token exchange takes two steps — the pool admits the GitHub token as the
# account, then mints an access token for it — and each needs its own role.
resource "google_service_account_iam_member" "deployer_workload_identity_user" {
  for_each = local.deployers

  service_account_id = each.value.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.principal

  depends_on = [google_iam_workload_identity_pool_provider.github]
}

resource "google_service_account_iam_member" "deployer_token_creator" {
  for_each = local.deployers

  service_account_id = each.value.service_account_id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value.principal

  depends_on = [google_iam_workload_identity_pool_provider.github]
}
