#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Dispatches the apply workflow when develop has changes under its paths that
# no apply run has started on, as when GitHub drops a merge's push event.
# Writes dispatched=true|false to the step's outputs. Run it from a full-history
# checkout of develop.

set -euo pipefail

readonly workflow=terraform-apply.yml

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  local tool
  for tool in gh git yq; do
    command -v "${tool}" >/dev/null || die "${tool} not found in PATH"
  done
  [[ -n "${GITHUB_OUTPUT:-}" ]] || die "GITHUB_OUTPUT is unset; run inside a GitHub Actions step"
}

# The newest run whatever its outcome: a failed apply already emailed, and
# re-dispatching it would fail again daily.
newest_run_sha() {
  gh api "repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow}/runs?branch=develop&per_page=1" \
    --jq '.workflow_runs[0].head_sha // empty'
}

has_unapplied_changes() {
  local since="$1" paths
  [[ -n "${since}" ]] || return 0
  mapfile -t paths < <(yq '.on.push.paths[]' ".github/workflows/${workflow}")
  ! git diff --quiet "${since}" HEAD -- "${paths[@]}"
}

main() {
  check_preconditions

  local since
  since="$(newest_run_sha)"

  if ! has_unapplied_changes "${since}"; then
    echo "dispatched=false" >>"${GITHUB_OUTPUT}"
    return
  fi

  echo "::warning::No apply has run on develop's changes since ${since:-the first commit}"
  gh workflow run "${workflow}" --ref develop
  echo "dispatched=true" >>"${GITHUB_OUTPUT}"
}

main "$@"
