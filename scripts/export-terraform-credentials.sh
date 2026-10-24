#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Gives a workflow job the GitHub App, Cloudflare, and Grafana credentials that
# the infrastructure layer's providers need. Run it after the job authenticates
# as a deployer, passing its role: each deployer can read only its own
# Cloudflare token. scripts/infrastructure.sh does the same for a local apply.

set -euo pipefail

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  [[ "${1:-}" == ro || "${1:-}" == rw ]] || die "usage: $0 ro|rw"
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

# The heredoc form carries multi-line values.
write_env() {
  {
    echo "$1<<__GITHUB_ENV__"
    echo "$2"
    echo "__GITHUB_ENV__"
  } >>"${GITHUB_ENV}"
}

# The runner prints every later step's environment, so the mask must come
# first.
write_secret() {
  mask "$2"
  write_env "$1" "$2"
}

main() {
  check_preconditions "$@"

  local role="$1" app_id installation_id pem cloudflare_token grafana_token
  app_id="$(read_secret github-app-id)"
  installation_id="$(read_secret github-app-installation-id)"
  pem="$(read_secret github-app-private-key)"
  cloudflare_token="$(read_secret "cloudflare-api-token-deployer-${role}")"
  grafana_token="$(read_secret grafana-provisioner-token)"

  write_env GITHUB_APP_ID "${app_id}"
  write_env GITHUB_APP_INSTALLATION_ID "${installation_id}"
  write_secret GITHUB_APP_PEM_FILE "${pem}"
  write_secret CLOUDFLARE_API_TOKEN "${cloudflare_token}"
  write_secret GRAFANA_AUTH "${grafana_token}"
}

main "$@"
