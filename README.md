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
baseline, the apex `dungeon.studio` DNS zone, the GitHub org with its
repositories, labels, and rulesets, and the credentials for the Grafana Cloud
stack every product sends telemetry to.

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

These recipes make up the operator surface:

- `just bootstrap` — creates the `dungeon-studio-infrastructure` project, the
  `dungeon-studio-tfstate` state bucket, the Workload Identity Federation pool,
  the deployer service accounts, the Cloudflare zone, and the zone's deployer
  tokens, then prompts for the GitHub App credentials the infrastructure layer
  authenticates with. Run it once per machine, or to rotate the deployer
  credentials.
- `just infrastructure` — local `terraform apply` against the infrastructure
  layer. Merging to `develop` applies this layer in continuous integration, so
  run the recipe only for the first apply after bootstrap or while that
  workflow is broken. It reads the GitHub App credentials out of Secret
  Manager, so register the App before the first run.
- `just configure-hook-fix` — writes the hook-fix App's credentials to the
  repositories Renovate automerges. Run it after registering the App or
  rotating its key.
- `just configure-grafana-gcp` — sets the service account key on the Grafana
  data sources that query GCP. Run it after Terraform creates or recreates one,
  or after rotating the key.

## Layout

Terraform splits into two layers on credentials and blast radius rather than
on provider. `terraform/bootstrap/` runs rarely, with elevated human
credentials, and provisions the state backend. It also holds the
`dungeon.studio` Cloudflare zone, because recreating the zone forces a
registrar change. `terraform/infrastructure/` holds the steady-state org
configuration, consumes what bootstrap produced, and is applied by continuous
integration on each merge to `develop`.

Each layer stores state in its own bucket: `dungeon-studio-tfstate` for
bootstrap, `dungeon-studio-infrastructure-tfstate` for the infrastructure
layer. Bootstrap grants the deployer service accounts access to the second
bucket alone. A bucket is the smallest thing those grants can name, so
continuous integration cannot read or rewrite the state that defines its own
credentials. `genshin.dungeon.studio` keeps a separate bucket in its own
project on the same reasoning.

Declare a repository as a call to `terraform/modules/github_repository/`,
which holds the org's defaults: Git flow, its rulesets, and read-only
workflow tokens. The call names only what differs.

## Run the first-time bootstrap

Beyond just and pre-commit you need:

- [Terraform](https://terraform.io) and the
  [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- a Google account that can create GCP projects and link billing
- Super Administrator on the `dungeon-studio` Cloudflare account

The `dungeon-studio` account holds this zone and nothing else. If the account
is gone, create it under **Accounts**, then **Create Account**, and set its ID
as `cloudflare_account_id` in `terraform/bootstrap/locals.tf`.

Log in twice. The bootstrap script calls `gcloud`, which uses its own
credentials, and Terraform reads application default credentials, which
`gcloud auth login` does not write:

```sh
gcloud auth login
gcloud auth application-default login

just bootstrap
```

The recipe prompts for the billing account to attach and for short-lived
[Grafana Cloud](docs/how-to/create-grafana-cloud-bootstrap-token.md) and
[Cloudflare](docs/how-to/create-cloudflare-bootstrap-token.md) bootstrap
tokens. Set `TF_VAR_billing_account_id`,
`TF_VAR_grafana_cloud_access_policy_token`, and
`TF_VAR_cloudflare_bootstrap_token` beforehand to run without a terminal.

Every step is idempotent, so a partial failure is safe to re-run.

The zone starts out pending. Cloudflare deletes it after 28 days unless the
registrar lists the zone's nameservers:

```sh
terraform -chdir=terraform/bootstrap output cloudflare_name_servers
```

If Cloudflare deleted the zone, drop it from state and bootstrap a new one:

```sh
terraform -chdir=terraform/bootstrap state rm cloudflare_zone.dungeon_studio
just bootstrap
```

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
Renovate branches. Its credentials are Actions secrets, not Terraform
resources, so the key stays out of state.
[Create the hook-fix GitHub App](docs/how-to/create-hook-fix-github-app.md)
registers it, sets the secrets, and rotates the key.

## Connect a product to Grafana Cloud

Bootstrap creates the credentials products use to reach the `dungeonstudio`
stack:

- Reading metrics. Grafana queries Cloud Monitoring as `grafana-gcp-reader`,
  which holds no roles here. A product grants it `roles/monitoring.viewer` on
  each of its projects. [Connect Grafana to Cloud
  Monitoring](docs/how-to/connect-grafana-to-gcp.md) sets the data source's
  key and checks a query.
- Sending telemetry. Each product environment has its own write-only token
  for metrics, logs, and traces, in this project's
  `grafana-push-token-<project>` secret. Products read the secret in place
  rather than copying it, so rotating a token touches one place. Add a product
  environment to `grafana_push_environments` in
  `terraform/bootstrap/grafana_push_tokens.tf`, and grant its runtime identity
  `roles/secretmanager.secretAccessor` on the secret there too.

## Contributing

This is infrastructure maintained for the organization's own use. Issues and
pull requests from outside collaborators are not actively solicited and may
not be triaged.

## License

MIT — see [LICENSES/MIT.txt](LICENSES/MIT.txt) or the
`SPDX-License-Identifier` headers on each file.
