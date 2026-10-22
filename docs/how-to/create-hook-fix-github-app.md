<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Create the hook-fix GitHub App

A workflow pushes pre-commit hook fixes to Renovate branches as the
`dungeon-studio-hook-fix` App. A push made with `GITHUB_TOKEN` doesn't
trigger workflows, so the required checks would never re-run on the fixed
commit. A push made with an App token does.

This registers the App, installs it on the repositories Renovate automerges,
and writes its credentials to those repositories as Actions secrets. The
credentials stay out of Terraform, which would keep the key in state.

You need an owner role in the org and admin on each target repository.

The App exists with ID `5422895`, which `just configure-hook-fix` writes by
default. Re-registering it changes the ID, so follow every section below.

## Register the App

1. Open
   <https://github.com/organizations/dungeon-studio/settings/apps/new>.

2. Set **GitHub App name** to `dungeon-studio-hook-fix` and **Homepage
   URL** to
   <https://github.com/dungeon-studio/dungeon-studio-infrastructure>. A pull
   request's timeline credits its pushes to `dungeon-studio-hook-fix[bot]`,
   which tells a reviewer they aren't Renovate's.

3. Clear **Webhook → Active**. The App only pushes and never receives events.

4. Grant **Repository → Contents**, read and write, and no other permission.
   GitHub adds **Repository → Metadata**, read-only, on its own. Leave it.

   Leave **Workflows** at **No access**. A fix that touches
   `.github/workflows/` then fails to push instead of landing past review.

5. Under **Where can this GitHub App be installed?** choose **Only on this
   account**.

6. Select **Create GitHub App**, then record the **App ID** shown on the
   General tab.

7. Under **Private keys**, select **Generate a private key**. GitHub hands
   over the `.pem` once and keeps only its fingerprint.

## Install the App on the automerged repositories

From the App's **Install App** tab, install it on `dungeon-studio` with
**Only select repositories**, and select each repository Renovate automerges:
`genshin.dungeon.studio` today.

Keep that selection in step with `REPOS` in
`scripts/configure-hook-fix-secrets.sh`. A repository holding the secrets but
missing the installation cannot push.

## Set the Actions secrets

```sh
just configure-hook-fix
```

The recipe writes `HOOK_FIX_APP_ID` and `HOOK_FIX_APP_PRIVATE_KEY` to every
repository in `REPOS`, overwriting what is there. It prompts for the private
key's path; export `HOOK_FIX_APP_PRIVATE_KEY_PATH` beforehand to run without
a terminal. Export `HOOK_FIX_APP_ID` too if the App was re-registered.

Then destroy the downloaded key:

```sh
shred --remove ~/Downloads/dungeon-studio-hook-fix.*.private-key.pem
```

## Rotate the private key

An App holds two private keys at once, so the replacement works before the
old one goes away.

1. Generate a second private key under **Private keys** on the App's General
   tab.

2. Run `just configure-hook-fix` with the new key. Every listed repository
   receives it.

3. Delete the old key on the App's General tab.

4. Shred the downloaded `.pem`.
