#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Creates the GCP project and GCS bucket holding Terraform state — the two
# things terraform/bootstrap/ cannot create for itself, because its own state
# lives in them. Re-running is a no-op.

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dungeon-studio-org}"
PROJECT_NAME="${PROJECT_NAME:-Dungeon Studio Org}"
BUCKET_NAME="${BUCKET_NAME:-dungeon-studio-tfstate}"
LOCATION="${LOCATION:-europe-west2}"

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gcloud >/dev/null || die "gcloud not found in PATH"
  [[ -n "${TF_VAR_billing_account_id:-}" ]] ||
    die "TF_VAR_billing_account_id is unset; see docs/how-to/bootstrap.md"
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

  # Outside the conditional so an existing bucket converges too. Object
  # versioning is what makes a truncated or corrupted state file recoverable;
  # without it the bucket holds one copy of everything.
  gcloud storage buckets update "gs://${BUCKET_NAME}" \
    --project "${PROJECT_ID}" \
    --versioning
}

main() {
  check_preconditions
  ensure_project
  ensure_billing_link
  ensure_state_bucket
}

main "$@"
