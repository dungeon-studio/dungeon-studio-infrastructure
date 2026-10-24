# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# One write credential per product environment, so revoking one environment's
# token leaves the others sending.
locals {
  grafana_push_environments = toset([
    "dungeon-studio-genshin-dev",
    "dungeon-studio-genshin-staging",
    "dungeon-studio-genshin-prod",
  ])
}

resource "grafana_cloud_access_policy" "push" {
  for_each = local.grafana_push_environments

  region = data.grafana_cloud_stack.this.region_slug
  name   = "${each.key}-push"
  scopes = ["metrics:write", "logs:write", "traces:write"]

  realm {
    type       = "stack"
    identifier = data.grafana_cloud_stack.this.id
  }
}

# No expires_at: a lapse would silently stop ingestion, and nothing renews the
# token. Rotation is a bootstrap run that taints it.
resource "grafana_cloud_access_policy_token" "push" {
  for_each = local.grafana_push_environments

  region           = data.grafana_cloud_stack.this.region_slug
  access_policy_id = grafana_cloud_access_policy.push[each.key].policy_id
  name             = grafana_cloud_access_policy.push[each.key].name
}

# Products read their token from this secret rather than holding a copy, so
# rotation touches one place.
resource "google_secret_manager_secret" "grafana_push_token" {
  for_each = local.grafana_push_environments

  project   = google_project.infrastructure.project_id
  secret_id = "grafana-push-token-${each.key}"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "grafana_push_token" {
  for_each = local.grafana_push_environments

  secret      = google_secret_manager_secret.grafana_push_token[each.key].id
  secret_data = grafana_cloud_access_policy_token.push[each.key].token
}
