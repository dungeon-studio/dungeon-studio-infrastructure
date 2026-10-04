# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  # Pinning each check to GitHub Actions stops another app from satisfying it
  # by reporting under the same name.
  github_actions_app_id = 15368

  # Only checks that report on every pull request and fail on the change
  # alone. A path-gated job never reports on most pull requests, and one that
  # fails on newly disclosed advisories blocks merges with no change to fix.
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

# A ruleset of its own rather than a rule on "Protect develop branch": the
# provider cannot express that ruleset's code_quality rule, so managing it
# would strip the rule on the next apply. GitHub enforces every ruleset that
# matches a branch.
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
      # Requiring up-to-date branches would reset Renovate's
      # minimumReleaseAge on every rebase, so a dependency pull request is
      # never both current and aged.
      strict_required_status_checks_policy = false

      dynamic "required_check" {
        for_each = local.genshin_required_checks
        content {
          context        = required_check.value
          integration_id = local.github_actions_app_id
        }
      }
    }
  }
}
