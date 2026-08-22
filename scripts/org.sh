#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Post-merge apply for the org layer. The github provider authenticates as a
# GitHub App whose credentials terraform/bootstrap/ keeps in Secret Manager;
# this reads them into the environment the provider expects, so the private
# key never lands on disk or in Terraform state.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dungeon-studio-infrastructure}"
LAYER="terraform/org"

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  command -v terraform >/dev/null || die "terraform not found in PATH"
}

read_secret() {
  gcloud secrets versions access latest --secret "$1" --project "${PROJECT_ID}" ||
    die "cannot read secret $1 — see docs/how-to/create-github-app.md"
}

# A secret with no versions fails the read, which set -e turns into an exit
# before terraform runs. Without that the provider would fall back to a
# personal token and apply as whoever ran it.
export_github_app_credentials() {
  GITHUB_APP_ID="$(read_secret github-app-id)"
  GITHUB_APP_INSTALLATION_ID="$(read_secret github-app-installation-id)"
  GITHUB_APP_PEM_FILE="$(read_secret github-app-private-key)"

  export GITHUB_APP_ID GITHUB_APP_INSTALLATION_ID GITHUB_APP_PEM_FILE
}

main() {
  cd "$(git rev-parse --show-toplevel)" || die "not inside a git work tree"

  check_preconditions
  export_github_app_credentials

  terraform -chdir="${LAYER}" init
  terraform -chdir="${LAYER}" apply
}

main "$@"
