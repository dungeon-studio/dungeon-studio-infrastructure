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

# Creating this resource returns a 409 from GitHub, but the repository's live
# Actions settings already match the config, so adopt them instead.
import {
  to = module.renovate_config.github_actions_repository_permissions.this
  id = "renovate-config"
}
