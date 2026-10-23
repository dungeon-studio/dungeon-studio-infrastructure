# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Empty shells, filled by scripts/bootstrap.sh as github_app's are. No deployer
# is granted access: only bootstrap reads them, to copy them to
# genshin.dungeon.studio.
resource "google_secret_manager_secret" "game_data_app" {
  for_each = toset([
    "game-data-app-client-id",
    "game-data-app-private-key",
  ])

  project   = google_project.infrastructure.project_id
  secret_id = each.value

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}
