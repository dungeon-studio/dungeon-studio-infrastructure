# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  project_id = "dungeon-studio-org"

  # backend.tf repeats this literal; backend blocks cannot interpolate.
  state_bucket = "dungeon-studio-tfstate"

  github_repository = "dungeon-studio/dungeon-studio-infrastructure"
}
