<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Run the first-time bootstrap

Stands up the Terraform state backend and the GCP identities continuous
integration authenticates as: the `dungeon-studio-org` project, the
`dungeon-studio-tfstate` bucket, a Workload Identity Federation pool scoped to
this repository, and the read-only and read-write deployer service accounts.

Run it when starting from a clean checkout, or when rotating those credentials.
Every step is idempotent, so a partial failure is safe to re-run.

This guide assumes you can create GCP projects and link the billing account.
It does not cover the GitHub App that authenticates the Terraform `github`
provider, or the workflows that consume these identities.

## Prerequisites

- [just](https://just.systems), [Terraform](https://terraform.io), and the
  [gcloud CLI](https://cloud.google.com/sdk/docs/install).
- The ID of the billing account to attach, in `XXXXXX-XXXXXX-XXXXXX` form.
  `gcloud billing accounts list` prints the ones you can use.

## Run

Terraform and the bootstrap script both authenticate as you, so log in with
application default credentials rather than a service account key:

```sh
gcloud auth application-default login
export TF_VAR_billing_account_id=XXXXXX-XXXXXX-XXXXXX

just bootstrap
```

The recipe runs three steps in order:

1. `scripts/bootstrap-terraform-state.sh` creates the project, links billing,
   and creates the versioned state bucket. Terraform cannot do this itself —
   its own state lives in that bucket.
2. `terraform -chdir=terraform/bootstrap init` configures the GCS backend.
3. `terraform -chdir=terraform/bootstrap apply` adopts the project through an
   `import` block and creates the federation pool, the deployer service
   accounts, and their IAM.

## Read the results

Later work needs the identifiers this layer produced:

```sh
terraform -chdir=terraform/bootstrap output
```

`workload_identity_provider` and the two service account emails are what a
GitHub Actions workflow passes to `google-github-actions/auth`. `project_id`
and `project_number` are what `terraform/org/` reads back over
`terraform_remote_state`.

## Where state lives

One bucket holds every layer in this repository, each under its own prefix:
`bootstrap` for this layer, `org` for `terraform/org/`. The bucket has object
versioning enabled, public access prevention, and uniform bucket-level access.

`genshin.dungeon.studio` keeps its state in a separate bucket in its own
project. The two are deliberately not shared — separate buckets are what stop
a plan job in one repository from reading the other's state.
