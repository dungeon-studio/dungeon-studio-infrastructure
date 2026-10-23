# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  infrastructure_repository = "dungeon-studio-infrastructure"
}

module "dungeon_studio_infrastructure" {
  source = "../modules/github_repository"

  name        = local.infrastructure_repository
  description = "Organization infrastructure as code for Dungeon Studio, managed with Terraform."

  org_allowed_action_patterns = github_actions_organization_permissions.org.allowed_actions_config[0].patterns_allowed
}

import {
  to = module.dungeon_studio_infrastructure.github_repository.this
  id = local.infrastructure_repository
}

import {
  to = module.dungeon_studio_infrastructure.github_branch_default.this
  id = local.infrastructure_repository
}

import {
  to = module.dungeon_studio_infrastructure.github_repository_dependabot_security_updates.this
  id = local.infrastructure_repository
}

import {
  to = module.dungeon_studio_infrastructure.github_workflow_repository_permissions.this
  id = local.infrastructure_repository
}

import {
  to = module.dungeon_studio_infrastructure.github_actions_repository_permissions.this
  id = local.infrastructure_repository
}

# None of these is secret. Actions masks secrets in workflow logs, which would
# hide these values while debugging a failed federation.
resource "github_actions_variable" "gcp_deployer" {
  for_each = {
    GCP_WORKLOAD_IDENTITY_PROVIDER = local.bootstrap.workload_identity_provider
    GCP_DEPLOYER_RO_EMAIL          = local.bootstrap.github_deployer_ro_email
    GCP_DEPLOYER_RW_EMAIL          = local.bootstrap.github_deployer_rw_email
  }

  repository    = local.infrastructure_repository
  variable_name = each.key
  value         = each.value
}
