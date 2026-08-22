<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Create the GitHub App

The `github` provider in `terraform/org/` authenticates as a GitHub App
installed on the `dungeon-studio` org. This registers that App and stores its
credentials where `just org` reads them.

You need an owner role in the org and permission to add secret versions in
the `dungeon-studio-infrastructure` project.

## Register the App

1. Open
   <https://github.com/organizations/dungeon-studio/settings/apps/new>.

2. Set **GitHub App name** to `dungeon-studio-terraform` and **Homepage
   URL** to
   <https://github.com/dungeon-studio/dungeon-studio-infrastructure>.

3. Clear **Webhook → Active**. Terraform calls the API and never receives
   events.

4. Grant these permissions and no others:

   - **Repository → Administration**, read and write: repositories, their
     settings, and repository rulesets.
   - **Repository → Issues**, read and write: the shared label set.
   - **Organization → Administration**, read and write: org settings, org
     rulesets, and the Actions allowlist.
   - **Organization → Members**, read and write: teams and their
     membership.

   GitHub adds **Repository → Metadata**, read-only, on its own. Leave it.
   Extend the set when a resource in `terraform/org/` fails without it.

5. Under **Where can this GitHub App be installed?** choose **Only on this
   account**.

6. Select **Create GitHub App**, then record the **App ID** shown on the
   General tab.

7. Under **Private keys**, select **Generate a private key**. GitHub hands
   over the `.pem` once and keeps only its fingerprint.

## Install the App on the org

1. From the App's **Install App** tab, install it on `dungeon-studio` with
   **All repositories** selected. Terraform manages every repository in the
   org, and a subset leaves resources it cannot refresh.

2. Record the installation ID. It is the last path segment of the URL you
   land on:

   ```text
   https://github.com/organizations/dungeon-studio/settings/installations/<ID>
   ```

## Store the credentials

```sh
just bootstrap
```

Export `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and
`GITHUB_APP_PRIVATE_KEY_PATH` beforehand to answer the prompts without a
terminal.

Then destroy the downloaded key:

```sh
shred --remove ~/Downloads/dungeon-studio-terraform.*.private-key.pem
```

## Confirm the provider authenticates

```sh
just org
```

The apply prints `github_organization_id`.
