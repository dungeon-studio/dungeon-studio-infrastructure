#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# First-time setup. Creates the GCP project and GCS bucket holding Terraform
# state — which terraform/bootstrap/ cannot create for itself, because its own
# state lives in them — then applies that layer. Re-running is a no-op.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dungeon-studio-infrastructure}"
PROJECT_NAME="${PROJECT_NAME:-Dungeon Studio Infrastructure}"
BUCKET_NAME="${BUCKET_NAME:-dungeon-studio-tfstate}"
LOCATION="${LOCATION:-europe-west2}"
LAYER="terraform/bootstrap"

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  command -v terraform >/dev/null || die "terraform not found in PATH"
}

# Both the billing link below and `terraform apply` read this, and each would
# otherwise ask for it separately.
resolve_billing_account() {
  [[ -z "${TF_VAR_billing_account_id:-}" ]] || return

  [[ -t 0 ]] || die "TF_VAR_billing_account_id is unset and stdin is not a terminal"

  # A closed account cannot be linked, so offering one is a dead end. ID first
  # in each row: display names contain spaces, IDs do not.
  local -a accounts=()
  local account
  while IFS= read -r account; do
    accounts+=("${account}")
  done < <(gcloud billing accounts list --filter=open=true \
    --format='value[separator=" "](name.basename(), displayName)')

  if ((${#accounts[@]} == 0)); then
    die "no open billing account available to ${USER}"
  elif ((${#accounts[@]} == 1)); then
    TF_VAR_billing_account_id="${accounts[0]%% *}"
  else
    local choice
    PS3="Billing account: "
    select choice in "${accounts[@]}"; do
      [[ -n "${choice}" ]] || continue
      TF_VAR_billing_account_id="${choice%% *}"
      break
    done
  fi

  export TF_VAR_billing_account_id
  echo "Using billing account ${TF_VAR_billing_account_id}"
}

ensure_project() {
  if gcloud projects describe "${PROJECT_ID}" >/dev/null 2>&1; then
    echo "Project ${PROJECT_ID} already exists."
    return
  fi

  echo "Creating project ${PROJECT_ID}"
  gcloud projects create "${PROJECT_ID}" --name "${PROJECT_NAME}"
}

# A bucket cannot be created in a project with no open billing account, and
# terraform/bootstrap/ cannot link one before its state has somewhere to live.
ensure_billing_link() {
  local linked
  linked="$(gcloud billing projects describe "${PROJECT_ID}" \
    --format='value(billingAccountName)' 2>/dev/null || true)"

  if [[ "${linked}" == "billingAccounts/${TF_VAR_billing_account_id}" ]]; then
    echo "Billing account ${TF_VAR_billing_account_id} already linked."
    return
  fi

  echo "Linking billing account ${TF_VAR_billing_account_id}"
  gcloud billing projects link "${PROJECT_ID}" \
    --billing-account "${TF_VAR_billing_account_id}"
}

ensure_state_bucket() {
  if gcloud storage buckets describe "gs://${BUCKET_NAME}" \
    --project "${PROJECT_ID}" >/dev/null 2>&1; then
    echo "Bucket gs://${BUCKET_NAME} already exists."
  else
    echo "Creating bucket gs://${BUCKET_NAME}"
    gcloud storage buckets create "gs://${BUCKET_NAME}" \
      --project "${PROJECT_ID}" \
      --location "${LOCATION}" \
      --public-access-prevention \
      --uniform-bucket-level-access
  fi

  # Runs unconditionally so an existing bucket converges. Versioning is what
  # makes a corrupted state file recoverable.
  gcloud storage buckets update "gs://${BUCKET_NAME}" \
    --project "${PROJECT_ID}" \
    --versioning
}

apply_bootstrap_layer() {
  terraform -chdir="${LAYER}" init
  terraform -chdir="${LAYER}" apply
}

main() {
  cd "$(git rev-parse --show-toplevel)" || die "not inside a git work tree"

  check_preconditions
  resolve_billing_account
  ensure_project
  ensure_billing_link
  ensure_state_bucket
  apply_bootstrap_layer
}

main "$@"
