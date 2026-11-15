# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

module "renovate_config" {
  source = "../modules/github_repository"

  name        = "renovate-config"
  description = "Shared Renovate preset for Dungeon Studio's repositories."
  topics      = ["renovate", "renovate-config", "dependency-management"]

  terraform_created = true

  org_allowed_action_patterns = local.org_allowed_action_patterns
}
