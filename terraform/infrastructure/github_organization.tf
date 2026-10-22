# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Exists so an apply exercises the App credentials; a provider no resource
# calls is never asked to authenticate. summary_only holds the read to
# GET /orgs/{org}, which the App's mandatory Metadata permission covers.
# Without it the data source also lists members and repositories.
data "github_organization" "org" {
  name         = local.github_owner
  summary_only = true
}

locals {
  # `@*` lets workflows pin actions by SHA. GitHub matches a pattern against
  # the ref as written, so `@v6` would reject a SHA pin of v6.
  allowed_action_patterns = [
    "actions/cache@*",
    "amannn/action-semantic-pull-request@*",
    "firebaseextended/action-hosting-deploy@v0",
    "lycheeverse/lychee-action@*",
    "peter-evans/create-issue-from-file@*",
    "pnpm/action-setup@*",
    "pre-commit/action@*",
    "release-drafter/*",
    "zizmorcore/zizmor-action@*",
  ]
}

import {
  to = github_actions_organization_permissions.org
  id = local.github_owner
}

resource "github_actions_organization_permissions" "org" {
  allowed_actions      = "selected"
  enabled_repositories = "all"
  sha_pinning_required = false

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = local.allowed_action_patterns
  }
}
