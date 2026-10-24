# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

terraform {
  required_version = ">= 1.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

provider "github" {
  owner = local.github_owner

  # Empty on purpose. Each argument falls back to GITHUB_APP_ID,
  # GITHUB_APP_INSTALLATION_ID, or GITHUB_APP_PEM_FILE, which
  # scripts/infrastructure.sh reads out of Secret Manager, keeping the key out
  # of configuration and state. Declaring the block is what makes a missing
  # value an error; without it the provider falls back to a personal access
  # token, or to `gh auth token`, and applies as whoever ran it.
  app_auth {}
}

# api_token falls back to CLOUDFLARE_API_TOKEN, which the scripts read out of
# Secret Manager.
provider "cloudflare" {}
