<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Run the first-time bootstrap

Creates the `dungeon-studio` project, the `dungeon-studio-tfstate` state
bucket, the Workload Identity Federation pool, and the deployer service
accounts. Run it from a clean checkout or to rotate those credentials; every
step is idempotent.

You need [Terraform](https://terraform.io), the
[gcloud CLI](https://cloud.google.com/sdk/docs/install), and an account that
can create GCP projects and link billing. `gcloud billing accounts list` prints
the account IDs available to you.

Log in twice. The bootstrap script calls `gcloud`, which uses its own
credentials, and Terraform reads application default credentials, which
`gcloud auth login` does not write:

```sh
gcloud auth login
gcloud auth application-default login
export TF_VAR_billing_account_id=XXXXXX-XXXXXX-XXXXXX

just bootstrap
```

Afterwards `terraform -chdir=terraform/bootstrap output` prints the federation
provider and deployer service account emails that GitHub Actions workflows
authenticate with.
