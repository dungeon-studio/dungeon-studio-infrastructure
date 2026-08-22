# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

resource "google_project_service" "secretmanager" {
  project = google_project.org.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false

  depends_on = [google_project_service.serviceusage]
}

locals {
  # The App ID and installation ID are not secret. They live here anyway:
  # none of the three exists until someone registers the App, so keeping them
  # together gives terraform/org/ nothing to hardcode and the how-to one
  # procedure to describe.
  github_app_secrets = toset([
    "github-app-id",
    "github-app-installation-id",
    "github-app-private-key",
  ])
}

# Empty shells. Versions are added out of band — see
# docs/how-to/create-github-app.md — because a version Terraform created
# would put the private key in this layer's state.
resource "google_secret_manager_secret" "github_app" {
  for_each = local.github_app_secrets

  project   = google_project.org.project_id
  secret_id = each.value

  replication {
    user_managed {
      replicas {
        location = "europe-west2"
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}
