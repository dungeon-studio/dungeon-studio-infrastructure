# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

module "genshin_dungeon_studio" {
  source = "../modules/github_repository"

  name        = "genshin.dungeon.studio"
  description = "Genshin Impact team builder — manage your character and weapon collection, build team compositions, and plan your roster."

  required_status_checks = {
    contexts = [
      "Audit workflows",
      "Build and test workspace",
      "Check pull request title",
      "Check schema compatibility",
      "Plan infrastructure",
      "Run end-to-end tests",
      "Run pre-commit hooks",
      "Scan and smoke-test container",
      "Scan Dockerfile",
      "Scan for verified secrets",
      "Scan Terraform",
      "Smoke-test dev stack",
      "Test against Firestore",
    ]
  }
  require_code_owner_review = true
  renovate_automerge        = true
  has_discussions           = true

  org_allowed_action_patterns = local.org_allowed_action_patterns

  # The copilot environment stays undeclared: GitHub manages it for the
  # Copilot coding agent.
  environments = {
    # core holds DNS for every environment. Applying it from release branches
    # too would let each branch revert the other's records.
    core = {
      deployment_branches = ["develop"]
      can_admins_bypass   = false
    }
    dev = {
      deployment_branches = ["develop"]
    }
    staging = {
      deployment_branches = ["release/*"]
    }
    prod = {
      deployment_branches = ["main"]
      reviewers           = ["alunduil"]
    }
  }

  legacy = {
    squash_only                      = true
    allowed_action_patterns          = local.allowed_action_patterns
    can_approve_pull_request_reviews = true
    dependabot_security_updates      = true
  }
}

moved {
  from = github_repository_ruleset.genshin_develop_ci
  to   = module.genshin_dungeon_studio.github_repository_ruleset.checks["develop"]
}
