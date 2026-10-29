# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

variable "billing_account_id" {
  type        = string
  description = "Billing account to attach to the project. Lives in bootstrap so the deployer service accounts never need billing permissions."

  validation {
    condition     = can(regex("^[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{6}$", var.billing_account_id))
    error_message = "Billing account ID must be 18 characters: XXXXXX-XXXXXX-XXXXXX (6 alphanumeric, hyphen, 6 alphanumeric, hyphen, 6 alphanumeric)"
  }
}

variable "grafana_cloud_access_policy_token" {
  type        = string
  sensitive   = true
  description = <<-EOT
    Grafana Cloud access policy token for this run. Delete it afterwards.

    1. Open https://dungeonstudio.grafana.net/a/grafana-auth-app
    2. On dungeon-studio-infrastructure-bootstrap, choose Add token.
    3. Set a one-day expiry and copy the token.
  EOT
}

variable "cloudflare_bootstrap_token" {
  type        = string
  sensitive   = true
  description = <<-EOT
    Bootstrap Cloudflare token, created by hand and revoked after apply.
    Export it as TF_VAR_cloudflare_bootstrap_token: a token pasted at this
    prompt can arrive corrupted.

    Create it under My Profile, not the account's Account API tokens page,
    whose tokens cannot mint other tokens. At
    https://dash.cloudflare.com/profile/api-tokens choose
    Create Custom Token and name it dungeon-studio-bootstrap. Each row's
    group dropdown defaults to Account, so set it per row:

      Account | Account API Tokens      | Edit
      Account | Email Routing Addresses | Edit
      Zone    | Zone                    | Edit
      Zone    | DNS                     | Edit

    Set Account Resources to: Include | dungeon-studio, and
    Zone Resources to: Include | All zones from an account | dungeon-studio.

    Full steps: docs/how-to/create-cloudflare-bootstrap-token.md
  EOT
}
