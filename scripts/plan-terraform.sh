#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Plans the Terraform layer in the current directory and writes the plan's
# text to plan.txt in the workspace root. It retries a plan that fails on a
# transient provider error, so an outage doesn't fail the required check.
# It sets the step output changes to true or false, so a later step can gate
# on it after the plan is shown.

set -euo pipefail

readonly max_attempts=3
readonly backoff_seconds=30
readonly log=plan.log

# Matches how the Google and Grafana clients report a 5xx or a timeout.
# Configuration, permission, and other 4xx errors fail without a retry.
is_transient_failure() {
  grep -qE '(status( code)?|Error) 5[0-9]{2}|request timeout|i/o timeout|deadline exceeded' "${log}"
}

# -detailed-exitcode exits 2 on a successful plan with changes and 1 on an
# error.
plan() {
  terraform plan -input=false -lock=false -no-color -detailed-exitcode -out=tfplan 2>&1 | tee "${log}"
}

main() {
  local attempt status
  for ((attempt = 1; ; attempt++)); do
    status=0
    plan || status=$?
    ((status != 1)) && break
    is_transient_failure || exit 1
    ((attempt < max_attempts)) || exit 1
    echo "::warning::Plan attempt ${attempt} hit a transient upstream error; retrying."
    sleep $((backoff_seconds * attempt))
  done
  terraform show -no-color tfplan >"${GITHUB_WORKSPACE}/plan.txt"
  if ((status == 2)); then
    echo "changes=true" >>"${GITHUB_OUTPUT}"
  else
    echo "changes=false" >>"${GITHUB_OUTPUT}"
  fi
}

main "$@"
