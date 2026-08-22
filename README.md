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

The two operator entrypoints:

- `just bootstrap` — first-time setup and credential rotation. Provisions the
  Terraform state backend and the credentials later applies depend on.
- `just org` — local `terraform apply` against the org layer, run after
  merging to `develop`.

Neither is implemented yet. Each names its tracking issue when run.

## Layout

| Path                   | Holds                                             |
| ---------------------- | ------------------------------------------------- |
| `terraform/bootstrap/` | State backend and credentials, applied by hand    |
| `terraform/org/`       | Steady-state org config, applied after each merge |

The two Terraform layers split on credentials and blast radius, not on
provider: `bootstrap` runs rarely with elevated human credentials and produces
what `org` consumes.

## Contributing

Checks run through pre-commit; every hook must pass.

This is infrastructure maintained for the organization's own use. Issues and
pull requests from outside collaborators are not actively solicited and may
not be triaged.

## License

MIT — see [LICENSES/MIT.txt](LICENSES/MIT.txt) or the
`SPDX-License-Identifier` headers on each file.
