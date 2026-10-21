# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# None of these is secret. Actions masks secrets in workflow logs, and these
# values are what a failed federation needs read back.
resource "github_actions_variable" "gcp_deployer" {
  for_each = {
    GCP_WORKLOAD_IDENTITY_PROVIDER = local.bootstrap.workload_identity_provider
    GCP_DEPLOYER_RO_EMAIL          = local.bootstrap.github_deployer_ro_email
    GCP_DEPLOYER_RW_EMAIL          = local.bootstrap.github_deployer_rw_email
  }

  repository    = "dungeon-studio-infrastructure"
  variable_name = each.key
  value         = each.value
}
