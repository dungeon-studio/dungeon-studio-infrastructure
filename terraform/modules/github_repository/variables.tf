# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

variable "name" {
  type        = string
  description = "Repository name (the GitHub repository slug)."
}

variable "description" {
  type        = string
  default     = ""
  description = "Short repository description."
}

variable "homepage_url" {
  type        = string
  default     = null
  description = "Optional homepage URL surfaced on the repository page."
}

variable "topics" {
  type        = list(string)
  default     = []
  description = "GitHub topics applied to the repository."
}

variable "required_status_checks" {
  type = object({
    ci_results_check = optional(bool, false)
    contexts         = optional(list(string), [])
    strict           = optional(bool, true)
  })
  default     = null
  description = <<-EOT
    Status checks that must pass before merging into develop, main, or
    release/**. contexts are matched by check-run name and must come from
    GitHub Actions; strict requires a pull request into develop to be up to
    date first, which main and release/** always require. Omit to leave
    develop ungated. Only require check names that are unique on a
    pull request — a name shared by several workflows can't be pinned to
    one of them.

    ci_results_check also requires the aggregator job "Check CI results".
    A required check that stops reporting blocks merges indefinitely, the
    admin's included.
    Matrix leg names change with the versions they test, so a matrix repo
    requires the aggregator instead of its legs. The job must list every
    job it stands in for under needs: and run on pushes to develop.
  EOT
}

variable "require_code_owner_review" {
  type        = bool
  default     = false
  description = <<-EOT
    Require an approving review from a code owner before merging into
    develop, main, or release/**. Gates a pull request whenever CODEOWNERS assigns an
    owner to a changed path; with no .github/CODEOWNERS on that branch it
    gates nothing.
  EOT
}

variable "admin_only_updates" {
  type        = bool
  default     = true
  description = <<-EOT
    Only the repository admin, and Renovate under renovate_automerge, can
    update develop, main, or release/**, whether by push or by merging a
    pull request.
    Set false once others merge pull requests.
  EOT
}

variable "renovate_automerge" {
  type        = bool
  default     = false
  description = <<-EOT
    Renovate merges its own pull requests without review, once the
    required status checks pass. Only Renovate and the hook-fix App can
    push to its renovate/** branches, so its pull requests carry only
    their commits. Enables GitHub auto-merge, which ignores any check that
    isn't required.
  EOT

  validation {
    condition     = !var.renovate_automerge || var.required_status_checks != null
    error_message = "renovate_automerge needs required_status_checks; without them Renovate would merge on nothing."
  }
}

variable "has_discussions" {
  type        = bool
  default     = false
  description = "Enable GitHub Discussions on the repository."
}

variable "environments" {
  type = map(object({
    deployment_branches = optional(list(string), [])
  }))
  default     = {}
  description = <<-EOT
    Deployment environments, keyed by name. Each scopes its own secrets
    and gives a workflow a target to declare via `environment: <name>`.

    deployment_branches lists the refs a job may reference this
    environment from — i.e. the only refs that can read its secrets.
    Empty (the default) admits any ref. Maps to the environment's
    deployment branch policy (Settings → Environments → Deployment
    branches and tags), and is unrelated to rulesets.
  EOT
}

variable "legacy" {
  type = object({
    squash_only                      = optional(bool, false)
    hand_made_rulesets               = optional(bool, false)
    allow_auto_merge                 = optional(bool, false)
    allowed_action_patterns          = optional(list(string))
    can_approve_pull_request_reviews = optional(bool, false)
    dependabot_security_updates      = optional(bool, false)
  })
  default     = {}
  nullable    = false
  description = <<-EOT
    Settings a repository kept from before Terraform managed it, each
    holding it back from an org default until it adopts that default.
    A repository on every default omits this.

    squash_only: no main branch and squash merges only, instead of Git
    flow. Git flow has develop integrate feature work and main hold
    releases, merges every pull request with a merge commit, and
    protects main and release/** alongside develop.

    hand_made_rulesets: leave the repository's own rulesets in place of
    this module's branch and tag rulesets.

    allow_auto_merge: GitHub auto-merge without renovate_automerge's
    rulesets.

    allowed_action_patterns: a repository-level action allowlist,
    narrowing the org's, of GitHub-owned actions, verified Marketplace
    creators, and these owner/repo@* patterns.

    can_approve_pull_request_reviews: workflows' GITHUB_TOKEN may create
    and approve pull requests.

    dependabot_security_updates: Dependabot opens security fix pull
    requests.
  EOT
}
