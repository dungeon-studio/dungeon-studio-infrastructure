# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# default_branch holds the live value after refresh. A data source scoped to
# this check would defer its read to apply, so every plan would report a
# change. The attribute is deprecated only as an input.
check "default_branch_rename" {
  assert {
    condition = github_repository.this.default_branch == local.develop_branch
    # error_message must reference only plan-time-known values: a newly
    # created repo's default branch is unknown, and interpolating it here
    # would fail plan with "Invalid template interpolation value".
    error_message = "Repository ${var.name}: the live default branch differs from '${local.develop_branch}'. Use GitHub's Rename branch feature (Settings → Branches → Rename) before applying — Terraform won't rename the branch on its own, and only the UI rename preserves PR refs and forks."
  }
}
