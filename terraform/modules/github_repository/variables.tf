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

variable "visibility" {
  type        = string
  default     = "public"
  description = <<-EOT
    "public" or "private". The org is on GitHub Free, where a private
    repository cannot have rulesets, so a private repository also needs
    rulesets = false.
  EOT

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "visibility must be \"public\" or \"private\"."
  }
}

variable "git_flow" {
  type        = bool
  default     = true
  description = <<-EOT
    Follow Git flow: develop integrates feature work, main holds releases,
    and only release/* and hotfix/* pull requests merge into main. Creates
    main, enables merge commits for release and hotfix merges, and protects
    main alongside develop. Set false only to keep a repository without a
    main branch unchanged until it adopts Git flow.
  EOT
}

variable "rulesets" {
  type        = bool
  default     = true
  description = <<-EOT
    Manage this module's branch and tag rulesets. Set false only to keep a
    repository's hand-made rulesets unchanged until it adopts these.
  EOT
}

variable "required_status_checks" {
  type = object({
    ci_results_check = optional(bool, false)
    contexts         = optional(list(string), [])
    strict           = optional(bool, true)
  })
  default     = null
  description = <<-EOT
    Status checks that must pass before merging into develop or main.
    contexts are matched by check-run name and must come from GitHub
    Actions; strict requires the branch to be up to date first. Omit to
    leave develop ungated. Only require check names that are unique on a
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
    develop or main. Gates a pull request whenever CODEOWNERS assigns an
    owner to a changed path; with no .github/CODEOWNERS on that branch it
    gates nothing.
  EOT
}

variable "admin_only_updates" {
  type        = bool
  default     = true
  description = <<-EOT
    Only the repository admin, and Renovate under renovate_automerge, can
    update develop or main, whether by push or by merging a pull request.
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

variable "allow_auto_merge" {
  type        = bool
  default     = false
  description = <<-EOT
    Enable GitHub auto-merge without renovate_automerge's rulesets.
    renovate_automerge already enables it; set this only to keep a
    repository's existing setting until it adopts renovate_automerge.
  EOT
}

variable "has_discussions" {
  type        = bool
  default     = false
  description = "Enable GitHub Discussions on the repository."
}

variable "template" {
  type = object({
    owner                = string
    repository           = string
    include_all_branches = optional(bool, false)
  })
  default     = null
  description = "Template repository to seed this one from. Only meaningful at create time."
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

variable "pages" {
  type = object({
    cname          = optional(string)
    build_type     = optional(string, "workflow")
    https_enforced = optional(bool)
  })
  default     = null
  description = <<-EOT
    Enable GitHub Pages with the given CNAME, build_type, and HTTPS
    enforcement. A "legacy" build publishes the release branch: main
    under git_flow, develop otherwise. https_enforced can only be set true
    once GitHub has issued the Let's Encrypt cert (auto-provisioned
    shortly after the apex CNAME resolves); for first-time setup, tick
    "Enforce HTTPS" in Settings → Pages once the cert is ready and
    subsequent applies will treat the flag as a no-op confirmation.
  EOT
}

variable "allowed_action_patterns" {
  type        = list(string)
  default     = null
  description = <<-EOT
    Narrow the actions this repository may run to GitHub-owned actions,
    verified Marketplace creators, and these owner/repo@* patterns. Omit
    to defer to the org allowlist. Set only to keep a repository's
    existing list until it moves to the org allowlist.
  EOT
}

variable "can_approve_pull_request_reviews" {
  type        = bool
  default     = false
  description = <<-EOT
    Let workflows' GITHUB_TOKEN create and approve pull requests. Set true
    only to keep a repository's existing setting until it adopts the
    default.
  EOT
}

variable "dependabot_security_updates" {
  type        = bool
  default     = false
  description = <<-EOT
    Let Dependabot open security fix pull requests. Set true only to keep
    a repository's existing setting until it adopts the default.
  EOT
}
