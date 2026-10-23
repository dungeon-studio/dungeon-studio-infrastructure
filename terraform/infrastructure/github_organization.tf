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
    "dorny/paths-filter@*",
    "lycheeverse/lychee-action@*",
    "peter-evans/create-issue-from-file@*",
    "peter-evans/create-pull-request@*",
    "pnpm/action-setup@*",
    "pre-commit/action@*",
    "release-drafter/release-drafter/autolabeler@*",
    "release-drafter/release-drafter@*",
    "zizmorcore/zizmor-action@*",
  ]
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

locals {
  # The resource reference orders every repository's allowlist after the org's.
  org_allowed_action_patterns = github_actions_organization_permissions.org.allowed_actions_config[0].patterns_allowed
}
