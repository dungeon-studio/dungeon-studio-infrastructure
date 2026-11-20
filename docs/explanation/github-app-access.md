<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# GitHub App repository access

This page explains which repositories each GitHub App on the
`dungeon-studio` org can write to, and why. It covers the Apps granted
**Repository → Contents** write, because that permission lets an App push
commits and, where a ruleset allows it, merge. Apps that only read contents
are out of scope. For registering an App, see the how-tos it links to.

## Why the selections live outside Terraform

Each installation's repository selection is set in the org's settings by
hand. The `github` provider has a resource for it,
`github_app_installation_repositories`, but it rejects GitHub App
authentication. The endpoints behind it act for a user with admin on the
repository, and the infrastructure layer authenticates as an App so that
it never applies as whoever ran it. Adding a user-authenticated provider to
manage one setting would reintroduce the personal credential the layer was
built to avoid.

GitHub also refuses to remove a repository from an installation that covers
all repositories. Moving an installation from all repositories to a
selection is an owner's action in the UI either way.

## Each App's reach

### Renovate: all repositories

Renovate opens dependency updates in every repository, so it needs to push
branches everywhere. On repositories that set `renovate_automerge`, the
`admin-only` ruleset lets it merge as well. Narrowing it would mean
re-adding each new repository by hand for no reduction in what it can do to
the repositories it already serves.

### claude: all repositories

Claude sessions push branches and open pull requests through this App. The
org has three active repositories, and Claude is expected to work in each of
them, so a selection would list all three. Archived repositories are read-only whatever
the installation says.

The cost of all repositories is that a new repository receives Claude's
write access without anyone choosing it. That is the intended behaviour:
a new repository is one Claude is expected to work in. Revisit this if the
org gains a repository Claude should not touch.

### dungeon-studio-terraform: all repositories

Terraform manages every active repository in the org. It needs contents
write to create a Git flow repository's `main` branch, and a repository left
out of the installation leaves resources Terraform cannot refresh.
[Create the GitHub App](../how-to/create-github-app.md) records the
permission set.

### dungeon-studio-hook-fix: selected repositories

This App exists for one job: pushing pre-commit hook fixes to Renovate
branches so the required checks re-run. Only repositories that set
`renovate_automerge` run that job, so it is installed on those alone. The
`renovate` ruleset lets it push to Renovate branches past review, which
Renovate then merges, so its reach stays as narrow as that job. Its
credentials are Actions secrets on the same repositories, and a repository
holding them without the installation cannot push.
[Create the hook-fix GitHub App](../how-to/create-hook-fix-github-app.md)
keeps the selection and the secrets in step.
