# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Refresh sets the repository's default_branch to the live value. A scoped
# data source would defer its read to apply on every plan, so a plan with
# nothing to change would still exit 2 under -detailed-exitcode. The attribute
# is deprecated only as an input, and this module never sets it.
check "default_branch_rename" {
  assert {
    condition = github_repository.this.default_branch == local.develop_branch
    # error_message must reference only plan-time-known values: a newly
    # created repo's default branch is unknown, and interpolating it here
    # would fail plan with "Invalid template interpolation value".
    error_message = "Repository ${var.name}: the live default branch differs from '${local.develop_branch}'. Use GitHub's Rename branch feature (Settings → Branches → Rename) before applying — Terraform won't rename the branch on its own, and only the UI rename preserves PR refs and forks."
  }
}
