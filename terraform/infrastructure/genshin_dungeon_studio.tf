# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

module "genshin_dungeon_studio" {
  source = "../modules/github_repository"

  name            = "genshin.dungeon.studio"
  description     = "Genshin Impact team builder — manage your character and weapon collection, build team compositions, and plan your roster."
  has_discussions = true

  legacy = {
    squash_only                      = true
    hand_made_rulesets               = true
    allow_auto_merge                 = true
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

data "github_app" "actions" {
  slug = "github-actions"
}

locals {
  # A required check must report on every pull request and fail only on what
  # the pull request changes. Path-gated jobs skip most pull requests, leaving
  # them pending forever. Dependency scans fail on newly disclosed advisories,
  # blocking merges that changed nothing.
  genshin_required_checks = [
    "Audit workflows",
    "Build and test workspace",
    "Check pull request title",
    "Check schema compatibility",
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

# The provider cannot represent every setting on the "Protect develop branch"
# ruleset, such as its code_quality rule, so managing that ruleset would strip
# them. GitHub enforces every ruleset that matches a branch, so these checks
# take a ruleset of their own.
resource "github_repository_ruleset" "genshin_develop_ci" {
  name        = "Require CI on develop"
  repository  = "genshin.dungeon.studio"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/develop"]
      exclude = []
    }
  }

  rules {
    required_status_checks {
      # Requiring up-to-date branches makes Renovate rebase whenever develop
      # moves. Each rebase can pull a newer release and restart its
      # minimumReleaseAge wait, so the pull request may never merge.
      strict_required_status_checks_policy = false

      dynamic "required_check" {
        for_each = local.genshin_required_checks
        content {
          context = required_check.value
          # Stops another app from satisfying the check by reporting under
          # the same name.
          integration_id = data.github_app.actions.id
        }
      }
    }
  }
}
