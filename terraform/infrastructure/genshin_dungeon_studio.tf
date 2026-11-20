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
      "Preview release draft",
      "Preview stale pull request pruning",
      "Run end-to-end tests",
      "Run pre-commit hooks",
      "Scan and smoke-test container",
      "Scan Dockerfile",
      "Scan for verified secrets",
      "Scan Terraform",
      "Smoke-test dev stack",
      "Test against Firestore",
      "Verify toolchain",
    ]
    # Codecov reports patch coverage on every pull request, including ones
    # that change no covered code.
    app_contexts = {
      "codecov/patch" = "codecov"
    }
    # Two pull requests that each pass alone can still break develop
    # together, as in genshin.dungeon.studio#1302.
    merge_queue = true
  }
  # Outside admin-only, anyone with contents write can merge to develop
  # through the queue once the checks pass:
  # - the admin;
  # - the renovate, dungeon-studio-terraform, and dungeon-studio-hook-fix
  #   Apps (docs/explanation/github-app-access.md);
  # - release-notes.yml's draft job, the only workflow token with
  #   contents write. It runs only on pushes to develop.
  # The claude App's installation leaves this repository out, because an
  # outside @claude mention might make it merge (#261).
  admin_only_updates = {
    develop = false
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
    squash_only                 = true
    dependabot_security_updates = true
  }
}

moved {
  from = github_repository_ruleset.genshin_develop_ci
  to   = module.genshin_dungeon_studio.github_repository_ruleset.checks["develop"]
}
