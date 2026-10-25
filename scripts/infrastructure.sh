#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Local apply for the infrastructure layer when CI cannot apply it. The github
# provider authenticates as a GitHub App, the cloudflare provider as the
# read-write deployer, and the grafana provider as the stack provisioner, with
# credentials terraform/bootstrap/ keeps in Secret Manager.
# Reading them into the environment keeps the private key off disk and out of
# Terraform state.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dungeon-studio-infrastructure}"
LAYER="terraform/infrastructure"

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  command -v terraform >/dev/null || die "terraform not found in PATH"
}

# die runs inside the caller's command substitution, so its exit leaves only
# that subshell; set -e is what stops the script before terraform runs.
read_secret() {
  gcloud secrets versions access latest --secret "$1" --project "${PROJECT_ID}" ||
    die "cannot read secret $1 — see README §Run the first-time bootstrap"
}

export_provider_credentials() {
  GITHUB_APP_ID="$(read_secret github-app-id)"
  GITHUB_APP_INSTALLATION_ID="$(read_secret github-app-installation-id)"
  GITHUB_APP_PEM_FILE="$(read_secret github-app-private-key)"
  CLOUDFLARE_API_TOKEN="$(read_secret cloudflare-api-token-deployer-rw)"
  GRAFANA_AUTH="$(read_secret grafana-provisioner-token)"

  export GITHUB_APP_ID GITHUB_APP_INSTALLATION_ID GITHUB_APP_PEM_FILE \
    CLOUDFLARE_API_TOKEN GRAFANA_AUTH
}

apply_infrastructure_layer() {
  terraform -chdir="${LAYER}" init
  terraform -chdir="${LAYER}" apply
}

main() {
  cd "$(git rev-parse --show-toplevel)" || die "not inside a git work tree"

  check_preconditions
  export_provider_credentials
  apply_infrastructure_layer
}

main "$@"
