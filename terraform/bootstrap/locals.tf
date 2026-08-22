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

  # The provider default and the secret replicas both take this.
  # scripts/bootstrap.sh repeats it as LOCATION, which no expression can reach.
  region = "europe-west2"

  # The App ID and installation ID are not secret. They live here anyway:
  # none of the three exists until someone registers the App, so keeping them
  # together gives terraform/org/ nothing to hardcode and the how-to one
  # procedure to describe.
  github_app_secrets = toset([
    "github-app-id",
    "github-app-installation-id",
    "github-app-private-key",
  ])
}
