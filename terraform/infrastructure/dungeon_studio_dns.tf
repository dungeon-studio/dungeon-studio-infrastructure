# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Squarespace terminates TLS for its own hostnames, so its records stay
# unproxied.
locals {
  dungeon_studio_zone_id = local.bootstrap.cloudflare_zone_id

  squarespace_ttl = 14400

  squarespace_apex_addresses = toset([
    "198.49.23.144",
    "198.49.23.145",
    "198.185.159.144",
    "198.185.159.145",
  ])

  # The core environment of genshin.dungeon.studio owns this zone. Recreating
  # it there assigns new nameservers, which this set must follow.
  genshin_name_servers = toset([
    "ns-cloud-c1.googledomains.com",
    "ns-cloud-c2.googledomains.com",
    "ns-cloud-c3.googledomains.com",
    "ns-cloud-c4.googledomains.com",
  ])
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
