# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# The identity Grafana Cloud queries Cloud Monitoring as. It holds no roles in
# this project: each product grants it roles/monitoring.viewer on its own
# projects, so reading a product's metrics takes both repositories' consent.
#
# A key, because Grafana ties federated credentials to the signed-in user's
# session, and alert rules evaluate with no one signed in.
resource "google_service_account" "grafana_gcp_reader" {
  project      = google_project.infrastructure.project_id
  account_id   = "grafana-gcp-reader"
  display_name = "Grafana GCP Reader"
  description  = "Read-only identity Grafana Cloud uses to query Cloud Monitoring"

  depends_on = [google_project_service.iam]
}

resource "google_service_account_key" "grafana_gcp_reader" {
  service_account_id = google_service_account.grafana_gcp_reader.name
}

# No deployer can read this: a data source would keep it in the infrastructure
# layer's state, which plan on any pull request can read.
resource "google_secret_manager_secret" "grafana_gcp_reader_key" {
  project   = google_project.infrastructure.project_id
  secret_id = "grafana-gcp-reader-key"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "grafana_gcp_reader_key" {
  secret      = google_secret_manager_secret.grafana_gcp_reader_key.id
  secret_data = base64decode(google_service_account_key.grafana_gcp_reader.private_key)
}
