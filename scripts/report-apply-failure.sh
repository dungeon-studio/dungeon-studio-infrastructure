#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Reports a failed apply run to the admin through an issue assigned to them.
# GitHub emails a failed run only to its triggering actor, which is a bot for
# Renovate merges and Daily dispatches. Comments on the open report instead of
# opening another, so the admin closes one issue per incident.

set -euo pipefail

readonly title="Terraform infrastructure apply failed on develop"
readonly admin=alunduil

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gh >/dev/null || die "gh not found in PATH"
  local var
  for var in GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_SERVER_URL GITHUB_ACTOR; do
    [[ -n "${!var:-}" ]] || die "${var} is unset; run inside a GitHub Actions step"
  done
}

open_report() {
  gh api "repos/${GITHUB_REPOSITORY}/issues?state=open&creator=github-actions%5Bbot%5D&per_page=100" \
    --jq "[.[] | select(.title == \"${title}\")][0].number // empty"
}

main() {
  check_preconditions

  local run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  local body="Apply run ${run_url} failed (triggered by \`${GITHUB_ACTOR}\`)."
  local number
  number="$(open_report)"

  if [[ -n "${number}" ]]; then
    gh api "repos/${GITHUB_REPOSITORY}/issues/${number}/comments" -f body="${body}" >/dev/null
    echo "Commented on #${number}"
  else
    number="$(gh api "repos/${GITHUB_REPOSITORY}/issues" \
      -f title="${title}" -f body="${body}" -f "assignees[]=${admin}" -f "labels[]=bug" \
      --jq .number)"
    echo "Opened #${number}"
  fi
}

main "$@"
