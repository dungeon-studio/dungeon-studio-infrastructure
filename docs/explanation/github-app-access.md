<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# GitHub App repository access

Each GitHub App on the `dungeon-studio` org with **Repository → Contents**
write can push commits to the repositories it is installed on. Where a
ruleset allows it, it can also merge. Apps that only read contents are out
of scope.

## Why the selections live outside Terraform

Repository selections are set by hand in the org's settings. The `github`
provider's `github_app_installation_repositories` resource rejects GitHub
App authentication, because the endpoints behind it act for a user. The
infrastructure layer authenticates as an App so that an apply never runs
with a person's credentials. A second, user-authenticated provider for this
one setting would undo that.

GitHub also refuses to remove a repository from an installation that covers
all repositories. Narrowing an installation is an owner's action in the UI
regardless of Terraform.

## Each App's reach

### Renovate: all repositories

Renovate opens dependency updates in every repository, so it pushes
branches everywhere. On repositories that set `renovate_automerge`, the
`admin-only` ruleset also lets it merge. A selection would still list every
repository, so it would add a manual step per new repository and remove no
access.

### claude: all repositories

Claude sessions push branches and open pull requests through this App.
Claude works in every active repository, so a selection would list them
all. Archived repositories are read-only whatever the installation says.

The trade-off is that a new repository gets Claude's write access without
anyone choosing it. Narrow the installation if the org gains a repository
Claude should not touch.

### dungeon-studio-terraform: all repositories

Terraform manages every active repository in the org. It needs contents
write to create a Git flow repository's `main` branch. A repository outside
the installation leaves resources Terraform cannot refresh.
[Create the GitHub App](../how-to/create-github-app.md) lists the full
permission set.

### dungeon-studio-hook-fix: selected repositories

This App pushes pre-commit hook fixes to Renovate branches so the required
checks re-run. The `renovate` ruleset lets it push there without review,
and Renovate then merges the result. That trust belongs only where Renovate
automerges, so the App is installed only on repositories that set
`renovate_automerge`.
[Create the hook-fix GitHub App](../how-to/create-hook-fix-github-app.md)
keeps the selection and the App's Actions secrets in step.
