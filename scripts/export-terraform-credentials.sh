#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Writes the GitHub App credentials the infrastructure layer's github provider
# reads to GITHUB_ENV, for a workflow job already authenticated as a deployer.
# scripts/infrastructure.sh exports the same values for a local apply.

set -euo pipefail

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  [[ -n "${GITHUB_ENV:-}" ]] || die "GITHUB_ENV is unset; run inside a GitHub Actions step"
}

# die runs inside the caller's command substitution, so its exit leaves only
# that subshell; set -e is what stops the script.
read_secret() {
  gcloud secrets versions access latest --secret "$1" || die "cannot read secret $1"
}

# A workflow command occupies one line, so a multi-line value is masked only
# when each of its lines is masked separately.
mask() {
  sed '/^$/d; s|^|::add-mask::|' <<<"$1"
}

# The heredoc form carries multi-line values. The runner prints every later
# step's environment, so mask a secret before writing it.
write_env() {
  {
    echo "$1<<__GITHUB_ENV__"
    echo "$2"
    echo "__GITHUB_ENV__"
  } >>"${GITHUB_ENV}"
}

main() {
  check_preconditions

  local app_id installation_id pem
  app_id="$(read_secret github-app-id)"
  installation_id="$(read_secret github-app-installation-id)"
  pem="$(read_secret github-app-private-key)"

  mask "${pem}"

  write_env GITHUB_APP_ID "${app_id}"
  write_env GITHUB_APP_INSTALLATION_ID "${installation_id}"
  write_env GITHUB_APP_PEM_FILE "${pem}"
}

main "$@"
