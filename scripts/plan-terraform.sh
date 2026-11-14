#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Plans the Terraform layer in the current directory and writes the plan's
# text to plan.txt in the workspace root. It retries a plan that fails on a
# transient provider error, so an outage doesn't fail the required check.

set -euo pipefail

readonly max_attempts=3
readonly backoff_seconds=30
readonly log=plan.log

# Matches how the Google and Grafana clients report a 5xx or a timeout.
# Configuration, permission, and other 4xx errors fail without a retry.
is_transient_failure() {
  grep -qE '(status( code)?|Error) 5[0-9]{2}|request timeout|i/o timeout|deadline exceeded' "${log}"
}

plan() {
  terraform plan -input=false -lock=false -no-color -out=tfplan 2>&1 | tee "${log}"
}

main() {
  local attempt
  for ((attempt = 1; ; attempt++)); do
    plan && break
    is_transient_failure || exit 1
    ((attempt < max_attempts)) || exit 1
    echo "::warning::Plan attempt ${attempt} hit a transient upstream error; retrying."
    sleep $((backoff_seconds * attempt))
  done
  terraform show -no-color tfplan >"${GITHUB_WORKSPACE}/plan.txt"
}

main "$@"
