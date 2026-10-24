# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  # Extend only when a resource in terraform/infrastructure/ fails to plan or
  # apply without it.
  cloudflare_deployer_permissions = {
    ro = ["Zone Read", "DNS Read"]
    rw = ["Zone Read", "DNS Write"]
  }
}

# Matched by name in HCL: the data source's name filter needs a URL-encoded
# value.
data "cloudflare_account_api_token_permission_groups_list" "zone" {
  account_id = local.cloudflare_account_id
  scope      = "com.cloudflare.api.account.zone"
}

locals {
  cloudflare_zone_permission_group_ids = {
    for group in data.cloudflare_account_api_token_permission_groups_list.zone.result :
    group.name => group.id
  }
}

# CI keeps working after the user who ran bootstrap leaves the account.
resource "cloudflare_account_token" "deployer" {
  for_each = local.cloudflare_deployer_permissions

  account_id = local.cloudflare_account_id
  name       = "dungeon-studio-infrastructure-${each.key}"

  policies = [{
    effect = "allow"
    permission_groups = [
      for name in each.value :
      { id = local.cloudflare_zone_permission_group_ids[name] }
    ]
    resources = jsonencode({
      "com.cloudflare.api.account.zone.${cloudflare_zone.dungeon_studio.id}" = "*"
    })
  }]
}

# Terraform mints these tokens, so their values are in this layer's state
# whether or not a secret version holds them. Secret Manager carries each to
# its own deployer, since CI cannot read this state.
resource "google_secret_manager_secret" "cloudflare_api_token" {
  for_each = local.cloudflare_deployer_permissions

  project   = google_project.infrastructure.project_id
  secret_id = "cloudflare-api-token-deployer-${each.key}"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "cloudflare_api_token" {
  for_each = local.cloudflare_deployer_permissions

  secret      = google_secret_manager_secret.cloudflare_api_token[each.key].id
  secret_data = cloudflare_account_token.deployer[each.key].value
}

resource "google_secret_manager_secret_iam_member" "deployer_cloudflare_api_token" {
  for_each = local.cloudflare_deployer_permissions

  project   = google_project.infrastructure.project_id
  secret_id = google_secret_manager_secret.cloudflare_api_token[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.deployers[each.key].email}"
}
