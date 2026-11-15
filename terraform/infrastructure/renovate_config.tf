# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  renovate_config_repository = "renovate-config"
}

module "renovate_config" {
  source = "../modules/github_repository"

  name        = local.renovate_config_repository
  description = "Shared Renovate preset for Dungeon Studio's repositories."
  topics      = ["renovate", "renovate-config", "dependency-management"]

  terraform_created = true

  org_allowed_action_patterns = local.org_allowed_action_patterns
}

import {
  to = module.renovate_config.github_actions_repository_permissions.this
  id = local.renovate_config_repository
}
