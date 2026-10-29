# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# A token that can add destination addresses can add one it controls, verify
# it, and point privacy@ at it. Creating the address here keeps that out of the
# deployer tokens, whose routing rules stay disabled for any unverified
# destination.
resource "cloudflare_email_routing_address" "privacy" {
  account_id = local.cloudflare_account_id
  email      = "alunduil@gmail.com"
}
