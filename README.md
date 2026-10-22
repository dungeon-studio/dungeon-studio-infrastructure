<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# dungeon-studio-infrastructure

[![License](https://img.shields.io/github/license/dungeon-studio/dungeon-studio-infrastructure)](LICENSES/MIT.txt)
[![REUSE status](https://api.reuse.software/badge/github.com/dungeon-studio/dungeon-studio-infrastructure)](https://api.reuse.software/info/github.com/dungeon-studio/dungeon-studio-infrastructure)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovatebot)](renovate.json)

Organization infrastructure as code for Dungeon Studio, managed with Terraform.

**Repository:** <https://github.com/dungeon-studio/dungeon-studio-infrastructure>
**Author:** Alex Brandt \<<alunduil@gmail.com>\>

## Scope

Org-level state that no single product owns: the GCP project and billing
baseline, the apex `dungeon.studio` DNS zone, and the GitHub org with its
repositories, labels, and rulesets.

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

- `just bootstrap` — creates the `dungeon-studio-infrastructure` project, the
  `dungeon-studio-tfstate` state bucket, the Workload Identity Federation pool,
  and the deployer service accounts, then prompts for the GitHub App
  credentials the infrastructure layer authenticates with. Run it once per
  machine, or to rotate the deployer credentials.
- `just infrastructure` — local `terraform apply` against the infrastructure
  layer, run after merging to `develop`. It reads the GitHub App credentials
  out of Secret Manager, so register the App before the first run.

## Layout

Terraform splits into two layers on credentials and blast radius rather than
on provider. `terraform/bootstrap/` runs rarely, with elevated human
credentials, and provisions the state backend; `terraform/infrastructure/`
holds the steady-state org configuration, consumes what bootstrap produced,
and is applied after each merge.

Each layer stores state in its own bucket: `dungeon-studio-tfstate` for
bootstrap, `dungeon-studio-infrastructure-tfstate` for the infrastructure
layer. Bootstrap grants the deployer service accounts access to the second
bucket alone. A bucket is the smallest thing those grants can name, so
continuous integration cannot read or rewrite the state that defines its own
credentials. `genshin.dungeon.studio` keeps a separate bucket in its own
project on the same reasoning.

## Run the first-time bootstrap

Beyond the tooling above you need [Terraform](https://terraform.io), the
[gcloud CLI](https://cloud.google.com/sdk/docs/install), and an account that
can create GCP projects and link billing.

Log in twice. The bootstrap script calls `gcloud`, which uses its own
credentials, and Terraform reads application default credentials, which
`gcloud auth login` does not write:

```sh
gcloud auth login
gcloud auth application-default login

just bootstrap
```

The recipe lists your billing accounts and prompts for the one to attach. Set
`TF_VAR_billing_account_id` beforehand to skip the prompt; the run then needs
no terminal.

Every step is idempotent, so a partial failure is safe to re-run.

Once the GitHub App below is registered, `just infrastructure` sets the
federation provider and deployer service account emails as the Actions
variables that workflows authenticate with.

## Register the GitHub App

The infrastructure layer's `github` provider authenticates as a GitHub App, so
its permissions are visible in the org's settings and its key rotates without
touching anyone's account. Terraform creates the Secret Manager secrets that
hold the App's ID, installation ID, and private key, but leaves them empty.
`just bootstrap` prompts for the values, so the key material never reaches a
state file.

[Create the GitHub App](docs/how-to/create-github-app.md) registers it and
fills those secrets;
[Rotate the GitHub App's private key](docs/how-to/rotate-github-app-key.md)
replaces the key afterwards.

A second App, `dungeon-studio-hook-fix`, pushes pre-commit hook fixes to
Renovate branches. Its credentials are Actions secrets on the repositories
Renovate automerges, written by `just configure-hook-fix`;
[Create the hook-fix GitHub App](docs/how-to/create-hook-fix-github-app.md)
covers registration and key rotation.

## Contributing

This is infrastructure maintained for the organization's own use. Issues and
pull requests from outside collaborators are not actively solicited and may
not be triaged.

## License

MIT — see [LICENSES/MIT.txt](LICENSES/MIT.txt) or the
`SPDX-License-Identifier` headers on each file.
