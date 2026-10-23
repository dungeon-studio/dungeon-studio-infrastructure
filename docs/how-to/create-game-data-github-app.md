<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Create the game data GitHub App

genshin.dungeon.studio's `Refresh game data` job opens its pull requests as
the `dungeon-studio-game-data` App. A pull request opened with `GITHUB_TOKEN`
triggers no workflows, so CI would never gate the refresh. One opened with an
App token does.

This registers the App, installs it on genshin.dungeon.studio, stores its
credentials in Secret Manager, and copies them to genshin as
`GAME_DATA_APP_CLIENT_ID` (an Actions variable) and
`GAME_DATA_APP_PRIVATE_KEY` (an Actions secret).

You need an owner role in the org, admin on genshin.dungeon.studio, and
permission to add secret versions in the `dungeon-studio-infrastructure`
project.

## Register the App

1. Open
   <https://github.com/organizations/dungeon-studio/settings/apps/new>.

2. Set **GitHub App name** to `dungeon-studio-game-data` and **Homepage
   URL** to
   <https://github.com/dungeon-studio/dungeon-studio-infrastructure>.

3. Clear **Webhook → Active**. The App opens pull requests and never receives
   events.

4. Grant these permissions and no others:

   - **Repository → Contents**, read and write: push the refresh branch.
   - **Repository → Pull requests**, read and write: open and update the
     refresh pull request.

   GitHub adds **Repository → Metadata**, read-only, on its own. Leave it.
   Leave **Workflows** at **No access**, so a refresh that touches
   `.github/workflows/` fails to push.

5. Under **Where can this GitHub App be installed?** choose **Only on this
   account**.

6. Select **Create GitHub App**, then record the **Client ID** shown on the
   General tab.

7. Under **Private keys**, select **Generate a private key**. GitHub hands
   over the `.pem` once and keeps only its fingerprint.

## Install the App on genshin.dungeon.studio

From the App's **Install App** tab, install it on `dungeon-studio` with
**Only select repositories**, and select `genshin.dungeon.studio` alone. A
token minted from this installation then cannot reach any other repository.

## Store the credentials

```sh
just bootstrap
```

The recipe prompts for the client ID and the private key's path, stores both
in Secret Manager, and sets them on genshin.dungeon.studio. Export
`GAME_DATA_APP_CLIENT_ID` and `GAME_DATA_APP_PRIVATE_KEY_PATH` beforehand to
answer the prompts without a terminal.

Re-running changes nothing: it skips populated secrets and leaves the
variable and secret on genshin as they are.

Then destroy the downloaded key:

```sh
shred --remove ~/Downloads/dungeon-studio-game-data.*.private-key.pem
```

## Confirm the App mints a token

Run genshin.dungeon.studio's `Daily` workflow by hand:

```sh
gh workflow run daily.yml --repo dungeon-studio/genshin.dungeon.studio
```

The `Refresh game data` job's token step succeeds.

## Rotate the private key

An App holds two private keys at once, so the replacement works before the
old one goes away. `just bootstrap` leaves populated values alone, so rotation
goes through `gcloud` and `gh`.

1. Generate a second private key under **Private keys** on the App's General
   tab.

2. Add it as a new secret version:

   ```sh
   gcloud secrets versions add game-data-app-private-key \
     --project dungeon-studio-infrastructure \
     --data-file ~/Downloads/<new-key>.private-key.pem
   ```

3. Copy it to genshin.dungeon.studio:

   ```sh
   gcloud secrets versions access latest \
     --secret game-data-app-private-key \
     --project dungeon-studio-infrastructure |
     gh secret set GAME_DATA_APP_PRIVATE_KEY \
       --repo dungeon-studio/genshin.dungeon.studio
   ```

4. Run the `Daily` workflow by hand and confirm the token step succeeds.

5. Delete the old key on the App's General tab.

6. Destroy the superseded secret version, which stays readable until you do:

   ```sh
   gcloud secrets versions destroy <N> \
     --secret game-data-app-private-key \
     --project dungeon-studio-infrastructure
   ```

7. Shred the downloaded `.pem`.
