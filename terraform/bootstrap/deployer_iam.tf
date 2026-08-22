# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# The two deployers take the same four grants and differ on exactly two axes.
# Stating the difference as a table keeps it reviewable: written out per
# account, a wrong bucket role or principal reads as symmetry.
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

# Authentication happens in two steps — the pool admits the GitHub token as
# the account, then an access token is minted for it — and each step is
# authorized by one of these roles.
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
