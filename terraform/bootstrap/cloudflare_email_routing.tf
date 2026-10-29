# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Account-scoped. A token that can add destinations can verify one it controls
# and forward privacy@ there, so the deployer tokens get rules only: a rule to
# an unverified destination stays disabled.
resource "cloudflare_email_routing_address" "privacy" {
  account_id = local.cloudflare_account_id
  email      = "alunduil@gmail.com"
}
