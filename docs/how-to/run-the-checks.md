<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Run the repository checks

Every check this repository enforces runs through pre-commit. Run them locally
before pushing so review isn't spent on formatting.

Assumes a working checkout and a Python environment you can install into.

## Install the hooks

```sh
pipx install pre-commit
pre-commit install
```

Hook environments are built on first run, which takes a few minutes. Later
runs reuse them.

## Run the hooks

```sh
pre-commit run --all-files   # everything
pre-commit run reuse --all-files   # one hook
```

A hook with no matching files reports `Skipped`, which is not a failure. The
Terraform and shell hooks report it today.

## Add a file that REUSE rejects

`reuse lint` fails on any file without an `SPDX-FileCopyrightText` and an
`SPDX-License-Identifier`. Add both as comments in the file's own syntax.
Where a format has no comment syntax, add a path annotation to
[`REUSE.toml`](../../REUSE.toml) instead.

Untracked files count. Anything git neither tracks nor ignores still has to
carry a header or an annotation.

## Move a hook to a newer version

Renovate opens the pull request. Adjust [`renovate.json`](../../renovate.json)
rather than editing a `rev:` by hand, so the pin and the policy stay together.
