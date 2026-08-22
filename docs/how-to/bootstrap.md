<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Run the first-time bootstrap

Stand up the Terraform state backend and the GCP identities continuous
integration authenticates as. The run creates:

- the `dungeon-studio` project and the `dungeon-studio-tfstate` bucket
- a Workload Identity Federation pool scoped to this repository
- the read-only and read-write deployer service accounts

Run it from a clean checkout, or to rotate those credentials. Every step is
idempotent, so a partial failure is safe to re-run.

This guide assumes you can create GCP projects and link the billing account.
It does not cover the GitHub App that authenticates the Terraform `github`
provider, or the workflows that consume these identities.

## Prerequisites

- [just](https://just.systems), [Terraform](https://terraform.io), and the
  [gcloud CLI](https://cloud.google.com/sdk/docs/install).
- The ID of the billing account to attach, in `XXXXXX-XXXXXX-XXXXXX` form.
  `gcloud billing accounts list` prints the ones you can use.

## Run the recipe

Terraform and the bootstrap script both authenticate as you, so log in with
application default credentials rather than a service account key:

```sh
gcloud auth application-default login
export TF_VAR_billing_account_id=XXXXXX-XXXXXX-XXXXXX

just bootstrap
```

Three steps run in order:

1. `scripts/bootstrap-terraform-state.sh` creates the project, links billing,
   and creates the versioned state bucket. Terraform cannot do this itself,
   because its own state lives in that bucket.
2. `terraform -chdir=terraform/bootstrap init` configures the GCS backend.
3. `terraform -chdir=terraform/bootstrap apply` adopts the project through an
   `import` block, then creates the federation pool, the deployer service
   accounts, and their IAM.

## Collect the identifiers

Continuous integration needs values this layer produced:

```sh
terraform -chdir=terraform/bootstrap output
```

A GitHub Actions workflow passes `workload_identity_provider` and one of the
two deployer emails to `google-github-actions/auth`.
