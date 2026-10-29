# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Squarespace terminates TLS for its own hostnames, so its records stay
# unproxied.
locals {
  squarespace_ttl = 14400

  squarespace_apex_addresses = toset([
    "198.49.23.144",
    "198.49.23.145",
    "198.185.159.144",
    "198.185.159.145",
  ])

  genshin_name_servers = toset([
    for name_server in data.google_dns_managed_zone.genshin.name_servers :
    trimsuffix(name_server, ".")
  ])

  # Keyed by key tag so a key-signing key rollover adds the new DS record
  # alongside the old one rather than replacing it.
  genshin_ds_records = {
    for key in data.google_dns_keys.genshin.key_signing_keys :
    key.key_tag => split(" ", key.ds_record) if key.is_active
  }
}

# The core environment of genshin.dungeon.studio owns this zone. Reading it
# here keeps the delegation and DS records following a recreated zone or a
# rotated key on the next apply.
data "google_dns_managed_zone" "genshin" {
  project = "dungeon-studio-genshin-core"
  name    = "genshin-dungeon-studio"
}

data "google_dns_keys" "genshin" {
  managed_zone = data.google_dns_managed_zone.genshin.id
}

resource "cloudflare_dns_record" "apex" {
  for_each = local.squarespace_apex_addresses

  zone_id = local.dungeon_studio_zone_id
  name    = "dungeon.studio"
  type    = "A"
  content = each.key
  ttl     = local.squarespace_ttl
  proxied = false
}

resource "cloudflare_dns_record" "apex_https" {
  zone_id = local.dungeon_studio_zone_id
  name    = "dungeon.studio"
  type    = "HTTPS"
  ttl     = local.squarespace_ttl

  data = {
    priority = 1
    target   = "."
    value    = format("alpn=%q ipv4hint=%q", "h2,http/1.1", join(",", local.squarespace_apex_addresses))
  }
}

resource "cloudflare_dns_record" "www" {
  zone_id = local.dungeon_studio_zone_id
  name    = "www.dungeon.studio"
  type    = "CNAME"
  content = "ext-sq.squarespace.com"
  ttl     = local.squarespace_ttl
  proxied = false
}

# Deleting this lapses the domain's Google verification.
resource "cloudflare_dns_record" "google_verification" {
  zone_id = local.dungeon_studio_zone_id
  name    = "47raxixnsgll.dungeon.studio"
  type    = "CNAME"
  content = "gv-wma5uc2xaguais.dv.googlehosted.com"
  ttl     = 300
  proxied = false
}

resource "cloudflare_dns_record" "genshin_delegation" {
  for_each = local.genshin_name_servers

  zone_id = local.dungeon_studio_zone_id
  name    = "genshin.dungeon.studio"
  type    = "NS"
  content = each.key
  ttl     = 21600
}

resource "cloudflare_dns_record" "genshin_ds" {
  for_each = local.genshin_ds_records

  zone_id = local.dungeon_studio_zone_id
  name    = "genshin.dungeon.studio"
  type    = "DS"
  ttl     = 21600
  data = {
    key_tag     = tonumber(each.value[0])
    algorithm   = tonumber(each.value[1])
    digest_type = tonumber(each.value[2])
    digest      = each.value[3]
  }
}
