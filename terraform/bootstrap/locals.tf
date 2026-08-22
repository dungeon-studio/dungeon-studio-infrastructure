# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  # Matches the repository name, as dungeon-studio-genshin-* match theirs. The
  # bare `dungeon-studio` is permanently reserved by a deleted project; GCP
  # never frees a project ID.
  project_id = "dungeon-studio-infrastructure"

  # backend.tf repeats this literal; backend blocks cannot interpolate.
  state_bucket = "dungeon-studio-tfstate"

  github_repository = "dungeon-studio/dungeon-studio-infrastructure"
}
