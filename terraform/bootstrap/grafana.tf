# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Everything that needs Grafana Cloud API auth lives in this layer. That auth
# can rewrite access policies, so in terraform/infrastructure/ it would let a
# pull request widen the token its own plan runs with.
#
# The stack is created by hand and read, not managed, so the bootstrap token
# needs only stacks:read.
data "grafana_cloud_stack" "this" {
  slug = "dungeonstudio"
}

# Admin because managing data sources needs it and a stack service account
# takes only a basic role. Admin has no read-only variant, so both deployers
# read the same token.
resource "grafana_cloud_stack_service_account" "provisioner" {
  stack_slug  = data.grafana_cloud_stack.this.slug
  name        = "dungeon-studio-infrastructure-provisioner"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "provisioner" {
  stack_slug         = data.grafana_cloud_stack.this.slug
  name               = grafana_cloud_stack_service_account.provisioner.name
  service_account_id = grafana_cloud_stack_service_account.provisioner.id
}

# Terraform writes this version, unlike the GitHub App's: the token exists only
# as a resource attribute, and no deployer can read this layer's state.
resource "google_secret_manager_secret" "grafana_provisioner_token" {
  project   = google_project.infrastructure.project_id
  secret_id = "grafana-provisioner-token"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "grafana_provisioner_token" {
  secret      = google_secret_manager_secret.grafana_provisioner_token.id
  secret_data = grafana_cloud_stack_service_account_token.provisioner.key
}
