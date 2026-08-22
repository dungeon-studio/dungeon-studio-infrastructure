<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Rotate the GitHub App's private key

This replaces the private key the `github` provider in `terraform/org/` signs
with, on an App that already authenticates.

You need admin on the App and permission to add and destroy secret versions
in the `dungeon-studio-infrastructure` project.

An App holds two private keys at once, so the replacement works before the
old one goes away. `just bootstrap` skips populated secrets, so this goes
through `gcloud`.

1. Generate a second private key under **Private keys** on the App's General
   tab.

2. Add it as a new secret version:

   ```sh
   gcloud secrets versions add github-app-private-key \
     --project dungeon-studio-infrastructure \
     --data-file ~/Downloads/<new-key>.private-key.pem
   ```

3. Run `just org`. A successful apply is the new key working.

4. Delete the old key on the App's General tab.

5. Destroy the superseded secret version, which stays readable until you do:

   ```sh
   gcloud secrets versions destroy <N> \
     --secret github-app-private-key \
     --project dungeon-studio-infrastructure
   ```

6. Shred the downloaded `.pem`.
