#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Reports a failed apply run to the admin through an issue assigned to them.
# GitHub emails a failed run only to its triggering actor, which is a bot for
# Renovate merges and Daily dispatches. Repeat failures land on the open
# report, so each incident is one issue to close.

set -euo pipefail

readonly title="Terraform infrastructure apply failed on develop"
readonly admin=alunduil
readonly reporter='github-actions[bot]'

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

find_open_report() {
  gh api -X GET "repos/${GITHUB_REPOSITORY}/issues" \
    -f state=open -f creator="${reporter}" -f per_page=100 \
    --jq "[.[] | select(.title == \"${title}\")][0].number // empty"
}

comment_on_report() {
  local number="$1" body="$2"
  gh api "repos/${GITHUB_REPOSITORY}/issues/${number}/comments" -f body="${body}" >/dev/null
  echo "Commented on #${number}"
}

file_report() {
  local body="$1" number
  number="$(gh api "repos/${GITHUB_REPOSITORY}/issues" \
    -f title="${title}" -f body="${body}" -f "assignees[]=${admin}" -f "labels[]=bug" \
    --jq .number)"
  echo "Opened #${number}"
}

main() {
  check_preconditions

  local run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  local body="Apply run ${run_url} failed (triggered by \`${GITHUB_ACTOR}\`)."
  local number
  number="$(find_open_report)"

  if [[ -n "${number}" ]]; then
    comment_on_report "${number}" "${body}"
  else
    file_report "${body}"
  fi
}

main "$@"
