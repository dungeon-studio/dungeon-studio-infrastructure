# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

module "genshin_dungeon_studio" {
  source = "../modules/github_repository"

  name            = "genshin.dungeon.studio"
  description     = "Genshin Impact team builder — manage your character and weapon collection, build team compositions, and plan your roster."
  has_discussions = true

  require_code_owner_review = true
  renovate_automerge        = true

  required_status_checks = {
    # A required check must report on every pull request and fail only on
    # what the pull request changes. Path-gated jobs skip most pull requests,
    # leaving them pending forever. Dependency scans fail on newly disclosed
    # advisories, blocking merges that changed nothing.
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
    # Requiring up-to-date branches makes Renovate rebase whenever develop
    # moves. Each rebase can pull a newer release and restart its
    # minimumReleaseAge wait, so the pull request may never merge.
    strict = false
  }

  legacy = {
    squash_only                      = true
    allowed_action_patterns          = local.allowed_action_patterns
    can_approve_pull_request_reviews = true
    dependabot_security_updates      = true
  }
}

import {
  to = module.genshin_dungeon_studio.github_repository.this
  id = "genshin.dungeon.studio"
}

import {
  to = module.genshin_dungeon_studio.github_branch_default.this
  id = "genshin.dungeon.studio"
}

import {
  to = module.genshin_dungeon_studio.github_repository_dependabot_security_updates.this
  id = "genshin.dungeon.studio"
}

import {
  to = module.genshin_dungeon_studio.github_workflow_repository_permissions.this
  id = "genshin.dungeon.studio"
}

import {
  to = module.genshin_dungeon_studio.github_actions_repository_permissions.this
  id = "genshin.dungeon.studio"
}

moved {
  from = github_repository_ruleset.genshin_develop_ci
  to   = module.genshin_dungeon_studio.github_repository_ruleset.checks["develop"]
}
