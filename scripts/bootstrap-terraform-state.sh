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

command -v gcloud >/dev/null || {
  echo "error: gcloud not found in PATH" >&2
  exit 1
}

BILLING_ACCOUNT_ID="${TF_VAR_billing_account_id:-}"
[[ -n "${BILLING_ACCOUNT_ID}" ]] || {
  echo "error: TF_VAR_billing_account_id is unset; see docs/how-to/bootstrap.md" >&2
  exit 1
}

if gcloud projects describe "${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Project ${PROJECT_ID} already exists."
else
  echo "Creating project ${PROJECT_ID}"
  gcloud projects create "${PROJECT_ID}" --name "${PROJECT_NAME}"
fi

# A bucket cannot be created in a project with no open billing account, and
# terraform/bootstrap/ cannot link one before its state has somewhere to live.
linked_account="$(gcloud billing projects describe "${PROJECT_ID}" \
  --format='value(billingAccountName)' 2>/dev/null || true)"
if [[ "${linked_account}" == "billingAccounts/${BILLING_ACCOUNT_ID}" ]]; then
  echo "Billing account ${BILLING_ACCOUNT_ID} already linked."
else
  echo "Linking billing account ${BILLING_ACCOUNT_ID}"
  gcloud billing projects link "${PROJECT_ID}" \
    --billing-account "${BILLING_ACCOUNT_ID}"
fi

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

# Object versioning is what makes a truncated or corrupted state file
# recoverable; a state bucket without it has one copy of everything.
gcloud storage buckets update "gs://${BUCKET_NAME}" \
  --project "${PROJECT_ID}" \
  --versioning
