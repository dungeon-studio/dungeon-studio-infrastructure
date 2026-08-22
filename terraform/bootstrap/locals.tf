# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  project_id = "dungeon-studio-org"

  # backend.tf repeats this literal because backend blocks cannot interpolate.
  state_bucket = "dungeon-studio-tfstate"

  # Bounds the federation pool and names the principal allowed into it. Both
  # uses have to agree or the pool admits tokens no service account trusts.
  github_repository = "dungeon-studio/dungeon-studio-infrastructure"
}
