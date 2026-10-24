<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Create the Cloudflare bootstrap token

`terraform/bootstrap/` uses this token to create the `dungeon.studio` zone and
mint the deployer tokens that continuous integration authenticates with. It
never enters continuous integration. Cloudflare shows a token's value only at
creation, so each `just bootstrap` run needs a new one.

You need Super Administrator on the `dungeon-studio` Cloudflare account.

1. At <https://dash.cloudflare.com/profile/api-tokens>, under **My Profile**,
   choose **Create Token**, then **Create Custom Token**, and name it
   `dungeon-studio-bootstrap`. A token from the account's **Account API
   tokens** page cannot mint other tokens. Under **Permissions** add these
   rows. Each
   row's group dropdown defaults to `Account`, so set it per row:

   | Group   | Permission           | Access |
   | ------- | -------------------- | ------ |
   | Account | `Account API Tokens` | Edit   |
   | Zone    | `Zone`               | Edit   |

   Set **Account Resources** to `Include`, then `dungeon-studio`. The zone does
   not exist on the first run, so set **Zone Resources** to `Include`, then
   `All zones from an account`, then `dungeon-studio`.

2. Under **TTL** set an end date a day or two out. The token stops working on
   its own, so a bootstrap run cannot leave a standing credential that creates
   tokens and zones.

3. Export it, then run bootstrap:

   ```sh
   export TF_VAR_cloudflare_bootstrap_token=...
   just bootstrap
   ```

   Exporting skips Terraform's prompt, which some terminals mangle pastes
   into.

4. Revoke the token once the apply succeeds, or let it expire.

Re-running bootstrap keeps the existing deployer tokens. To rotate them,
export a new bootstrap token and replace them:

```sh
terraform -chdir=terraform/bootstrap apply \
  -replace='cloudflare_account_token.deployer["ro"]' \
  -replace='cloudflare_account_token.deployer["rw"]'
```

The apply writes the new values to Secret Manager in the same run.
