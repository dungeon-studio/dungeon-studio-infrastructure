# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Also enables Email Routing, which cloudflare_email_routing_settings would
# own too; destroying either disables routing.
resource "cloudflare_email_routing_dns" "dungeon_studio" {
  zone_id = local.dungeon_studio_zone_id
}

resource "cloudflare_email_routing_rule" "privacy" {
  zone_id = local.dungeon_studio_zone_id
  name    = "privacy"
  enabled = true

  matchers = [{
    type  = "literal"
    field = "to"
    value = "privacy@dungeon.studio"
  }]

  actions = [{
    type  = "forward"
    value = [local.bootstrap.cloudflare_privacy_destination]
  }]

  depends_on = [cloudflare_email_routing_dns.dungeon_studio]
}
