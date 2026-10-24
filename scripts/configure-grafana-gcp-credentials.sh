#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Sets grafana-gcp-reader's key on the Grafana data sources that query GCP.
# Terraform can't set it: a data source keeps its credential in state, and pull
# request plans can read the infrastructure layer's state. The key never
# touches disk.
#
# Without arguments, targets every data source whose clientEmail is the key's
# service account.
#
# Usage: scripts/configure-grafana-gcp-credentials.sh [datasource-uid ...]

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dungeon-studio-infrastructure}"
GCX_CONTEXT="${GCX_CONTEXT:-dungeonstudio}"

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  command -v gcx >/dev/null || die "gcx not found in PATH"
  command -v jq >/dev/null || die "jq not found in PATH"
}

# die runs inside the caller's command substitution, so its exit leaves only
# that subshell; set -e is what stops the script.
read_secret() {
  gcloud secrets versions access latest --secret "$1" --project "${PROJECT_ID}" ||
    die "cannot read secret $1"
}

# gcx authenticates as the signed-in operator. The context is explicit because
# the current one may name another stack.
grafana_api() {
  gcx api --context "${GCX_CONTEXT}" "$@"
}

# The key travels by stdin and environment, never argv: /proc/<pid>/cmdline is
# world-readable, /proc/<pid>/environ is not. Terraform owns jsonData.
set_datasource_credential() {
  local uid="$1" private_key="$2"

  grafana_api "/api/datasources/uid/${uid}" |
    pk="${private_key}" jq '.secureJsonData = {privateKey: env.pk}' |
    grafana_api "/api/datasources/uid/${uid}" -X PUT -d @- >/dev/null

  echo "Set GCP credential on Grafana data source '${uid}'."
}

key_field() {
  k="$1" jq -rn --arg field "$2" 'env.k | fromjson | .[$field]'
}

datasources_using() {
  grafana_api /api/datasources |
    email="$1" jq -r '.[] | select(.jsonData.clientEmail == env.email) | .uid'
}

main() {
  check_preconditions

  local key private_key client_email matches uid
  local -a uids=("$@")

  key="$(read_secret grafana-gcp-reader-key)"
  private_key="$(key_field "${key}" private_key)"
  client_email="$(key_field "${key}" client_email)"

  if [[ ${#uids[@]} -eq 0 ]]; then
    matches="$(datasources_using "${client_email}")"
    [[ -n "${matches}" ]] || die "no Grafana data source uses ${client_email}"
    mapfile -t uids <<<"${matches}"
  fi

  for uid in "${uids[@]}"; do
    set_datasource_credential "${uid}" "${private_key}"
  done
}

main "$@"
