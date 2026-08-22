<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Run the repository checks

Every check this repository enforces runs through pre-commit, including the
ones CI runs. Run them locally before pushing so review isn't spent on
formatting.

Assumes a working checkout and a Python environment you can install into.

## Install the hooks

```sh
pipx install pre-commit
pre-commit install
```

Hook environments are built on first run, which takes a few minutes. Later
runs reuse them.

## Run against everything

```sh
pre-commit run --all-files
```

Hooks whose file types aren't present yet report `Skipped` — the Terraform and
shell hooks do this until `terraform/` and `scripts/` exist.

## Run one hook

```sh
pre-commit run reuse --all-files
```

## Add a file that REUSE rejects

`reuse lint` fails on any file without an `SPDX-FileCopyrightText` and an
`SPDX-License-Identifier`. Add both as comments in the file's own syntax. For
formats that have no comment syntax — JSON, generated lock files — add a path
annotation to [`REUSE.toml`](../../REUSE.toml) instead.

## Update a pinned hook version

Renovate opens the pull request. Change
[`renovate.json`](../../renovate.json) rather than editing a `rev:` by hand,
so the pin and the policy stay in one place.
