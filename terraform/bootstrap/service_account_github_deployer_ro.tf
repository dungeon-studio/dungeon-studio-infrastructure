# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

resource "google_service_account" "github_deployer_ro" {
  project      = google_project.org.project_id
  account_id   = "github-deployer-ro"
  display_name = "GitHub Planner"
  description  = "GitHub Actions service account with read-only access for plan runs"

  depends_on = [google_project_service.iam]
}

# Extend only when a resource in terraform/org/ fails to refresh without it.
resource "google_project_iam_custom_role" "github_deployer_ro_planner" {
  project     = google_project.org.project_id
  role_id     = "githubDeployerPlanner"
  title       = "GitHub Deployer Planner"
  description = "Least-privilege read role for terraform plan in CI"

  permissions = [
    "resourcemanager.projects.get",
    "serviceusage.services.get",
    "serviceusage.services.list",
  ]

  depends_on = [google_project_service.serviceusage]
}

resource "google_project_iam_member" "github_deployer_ro_planner" {
  project = google_project.org.project_id
  role    = google_project_iam_custom_role.github_deployer_ro_planner.name
  member  = "serviceAccount:${google_service_account.github_deployer_ro.email}"
}

resource "google_storage_bucket_iam_member" "github_deployer_ro_state_object_viewer" {
  bucket = data.google_storage_bucket.state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.github_deployer_ro.email}"
}

resource "google_storage_bucket_iam_member" "github_deployer_ro_state_bucket_reader" {
  bucket = data.google_storage_bucket.state.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.github_deployer_ro.email}"
}

resource "google_service_account_iam_member" "github_deployer_ro_workload_identity_user" {
  service_account_id = google_service_account.github_deployer_ro.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.wif_principal_repository

  depends_on = [google_iam_workload_identity_pool_provider.github]
}

resource "google_service_account_iam_member" "github_deployer_ro_token_creator" {
  service_account_id = google_service_account.github_deployer_ro.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.wif_principal_repository

  depends_on = [google_iam_workload_identity_pool_provider.github]
}
