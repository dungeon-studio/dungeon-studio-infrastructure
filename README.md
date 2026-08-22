<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# dungeon-studio-infrastructure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSES/MIT.txt)
[![REUSE status](https://api.reuse.software/badge/github.com/dungeon-studio/dungeon-studio-infrastructure)](https://api.reuse.software/info/github.com/dungeon-studio/dungeon-studio-infrastructure)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovatebot)](renovate.json)

Organization infrastructure as code for Dungeon Studio, managed with Terraform.

**Repository:** <https://github.com/dungeon-studio/dungeon-studio-infrastructure>
**Author:** Alex Brandt \<<alunduil@gmail.com>\>

## Scope

Org-level state that no single product owns: the GCP org and billing baseline,
the apex `dungeon.studio` DNS zone, and the GitHub org with its repositories,
labels, and rulesets.

Product infrastructure stays with its product. `genshin.dungeon.studio` owns
its own DNS zone in the
[monorepo](https://github.com/dungeon-studio/genshin.dungeon.studio)'s `core`
environment; the apex zone here delegates to it over NS.

## Getting started

Install [just](https://just.systems) and [pre-commit](https://pre-commit.com),
then put the commit gate in place:

```sh
pre-commit install
```

Every check this repository enforces runs through pre-commit, so that one
command is the whole local setup.

Two recipes make up the operator surface:

- `just bootstrap` — first-time setup and credential rotation. Provisions the
  Terraform state backend and the credentials later applies depend on.
- `just org` — local `terraform apply` against the org layer, run after
  merging to `develop`. Not implemented yet; it names its tracking issue when
  you run it.

## Run the first-time bootstrap

`just bootstrap` creates the `dungeon-studio` project, the
`dungeon-studio-tfstate` state bucket, the Workload Identity Federation pool,
and the deployer service accounts. Every step is idempotent, so a partial
failure is safe to re-run.

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

## Layout

Terraform splits into two layers on credentials and blast radius rather than
on provider. `terraform/bootstrap/` runs rarely, with elevated human
credentials, and provisions the state backend; `terraform/org/` holds the
steady-state org configuration, consumes what bootstrap produced, and is
applied after each merge.

Both layers store state in the `dungeon-studio-tfstate` bucket under their own
prefix. `genshin.dungeon.studio` keeps a separate bucket in its own project, so
neither repository's continuous integration can read the other's state.

## Contributing

This is infrastructure maintained for the organization's own use. Issues and
pull requests from outside collaborators are not actively solicited and may
not be triaged.

## License

MIT — see [LICENSES/MIT.txt](LICENSES/MIT.txt) or the
`SPDX-License-Identifier` headers on each file.
