# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# No deployer is granted access. CI never uses this App; only bootstrap reads
# the values, to copy them to genshin.dungeon.studio.
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
