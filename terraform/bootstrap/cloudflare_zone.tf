# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Recreating the zone mints a new nameserver pair, which forces a registrar
# change and an outage while it propagates, so it sits in the layer CI never
# applies. Creating it needs account-wide Zone Edit, which only the expiring
# operator token holds.
resource "cloudflare_zone" "dungeon_studio" {
  account = {
    id = local.cloudflare_account_id
  }
  name = "dungeon.studio"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

# With a DS record at .studio, disabling or re-keying this breaks validation of
# the whole zone until the registrar holds the new DS, so it shares the zone's
# layer.
resource "cloudflare_zone_dnssec" "dungeon_studio" {
  zone_id = cloudflare_zone.dungeon_studio.id
  status  = "active"

  lifecycle {
    prevent_destroy = true
  }
}
