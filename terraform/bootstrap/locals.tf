# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  # Matches the repository name, as dungeon-studio-genshin-* match theirs. The
  # bare `dungeon-studio` is permanently reserved by a deleted project; GCP
  # never frees a project ID.
  project_id = "dungeon-studio-infrastructure"

  # One bucket per layer, each named after the layer it serves. Only the
  # second name says so: the first predates the rule and already holds live
  # state, and renaming a bucket moves every object in it.
  #
  # Each layer's backend.tf repeats its own literal; backend blocks cannot
  # interpolate.
  bootstrap_state_bucket      = "dungeon-studio-tfstate"
  infrastructure_state_bucket = "dungeon-studio-infrastructure-tfstate"

  github_repository = "dungeon-studio/dungeon-studio-infrastructure"

  # scripts/bootstrap.sh repeats this literal as LOCATION; shell cannot read a
  # Terraform local.
  region = "europe-west2"

  # The App ID and installation ID are not secret. They live here because none
  # of the three exists until the App is registered, which leaves
  # terraform/infrastructure/ nothing to hardcode.
  github_app_secrets = toset([
    "github-app-id",
    "github-app-installation-id",
    "github-app-private-key",
  ])
}
