<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# dungeon-studio-infrastructure — agent guide

These rules apply to every coding agent. A tool that reads only its
own path gets a file there that imports this one and adds only rules
false for every other agent. `CLAUDE.md` is that file for Claude
Code.

## Contribution flow

Merging to `develop` applies the infrastructure layer in CI, so a
PR ships everything in it.

- **Open draft PRs only.** The default branch is `develop`, not
  `main`. Don't push to it; don't merge your own PRs. alunduil
  reviews and merges.
- **Don't run `terraform apply`.** alunduil applies bootstrap by
  hand because CI cannot reach its state (README §Layout).
- **Confirm scope doesn't overlap sibling or linked issues** before
  opening the PR; ask if uncertain.
- **Defer an issue blocked by unshipped prerequisites.** Propose a
  `blocked-by` edge rather than write premature code.
- **Revert incidental edits** (formatting, drive-by tweaks) before
  requesting review.
- **Follow-ups land in a new session and a new PR.** A merged PR is
  done — don't keep iterating on it for adjacent work.

## Layout

Two Terraform layers, split on credentials and blast radius — see
README §Layout for which holds what.

Product infrastructure stays with its product — README §Scope draws
the `genshin.dungeon.studio` boundary. Check it before adding a
product-scoped resource here.

## Gotchas

- Pre-commit hooks gate every commit; all must pass.
- New files need SPDX headers. Formats without comment syntax get a
  path annotation in `REUSE.toml` instead.
- `reuse lint` walks anything git neither tracks nor ignores, so a
  stray untracked file fails it too.
- Renovate owns pinned versions; change one by extending
  `renovate.json`.
