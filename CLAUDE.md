<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

<!--
Maintainer notes (HTML comments are stripped from Claude's context):
- AI-targeted, loaded every session. Optimise for tokens; keep
  under ~75 lines.
- Add an entry only when Claude has made the same mistake twice
  or a non-obvious convention bit a session.
- Prefer pointers (README §..., file:line) over copies of content
  that already lives elsewhere.
- Human-facing context lives in [README](README.md).
-->

# dungeon-studio-infrastructure — Claude guide

## Contribution flow

- **Open draft PRs only.** The default branch is `develop`, not
  `main`. Don't push to it; don't merge your own PRs. alunduil
  reviews and merges.
- **Don't run `terraform apply`.** alunduil runs it post-merge from
  the local shell. `terraform plan` output in the PR body is welcome.
- **Follow-ups land in a new session and a new PR.** A merged PR is
  done — don't keep iterating on it for adjacent work.

## Layout

Two Terraform layers, split on credentials and blast radius rather
than provider — see README §Layout for which holds what.

Product infrastructure stays with its product — README §Scope draws
the `genshin.dungeon.studio` boundary. Check it before adding a
product-scoped resource here.

## Scope discipline

`terraform apply` runs out-of-band post-merge, so an unrelated edit
in a scoped PR ships infra the reviewer didn't ask for.

- Confirm scope doesn't overlap sibling or linked issues before
  opening the PR; ask if uncertain.
- An issue blocked by unshipped prerequisites: propose deferral with
  a `blocked-by` edge rather than write premature code.
- Revert incidental edits (formatting, drive-by tweaks) before
  requesting review.

## Gotchas

- Pre-commit hooks gate every commit; all must pass. New files need
  SPDX headers — `reuse lint` flags missing ones, and it walks
  anything git neither tracks nor ignores. Formats without comment
  syntax get a path annotation in `REUSE.toml` instead.
- Renovate owns pinned versions. Extend `renovate.json` rather than
  editing a `rev:` by hand.
