<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# 1. Host the apex dungeon.studio zone on Cloudflare

## Status

Proposed

## Context and Problem Statement

The [genshin.dungeon.studio repository][genshin-repo] carries draft
privacy policy and terms of service pages ([#647][647]). The privacy
page records that it needs a dedicated contact address before the 1.0.0
tag. `privacy@dungeon.studio` is an apex-domain address, so whatever
delivers it constrains the apex zone.

The apex is already authoritative on Google Cloud DNS
(`ns-cloud-d1..d4.googledomains.com`), and DNSSEC-signed with a DS
record published at `.studio`. It answers with Squarespace A records.
It delegates `genshin.dungeon.studio` by NS to a second Cloud DNS zone
owned by the `core` environment of the
[genshin.dungeon.studio repository][genshin-repo]. None of it is under
Terraform here yet.

## Decision Drivers

1. Every piece of configuration lives in Terraform.
2. The forwarding destination stays out of public DNS. An address that
   exists to keep a personal inbox off a legal page cannot publish that
   inbox in a queryable record.
3. Vendors, credentials, and IAM surfaces stay few. Each is another
   token to rotate and another provider to keep current.
4. Recurring cost stays at zero. One forwarding address does not
   justify a subscription.

No option satisfies all four.

## Considered Options

- Cloudflare Email Routing
- ForwardEmail on Cloud DNS
- ImprovMX on Cloud DNS

## Decision Outcome

Chosen option: **Cloudflare Email Routing**. It is the only option
meeting drivers 1, 2, and 4, and the only one that requires moving the
apex.

The `genshin.dungeon.studio` zone stays in the [repository of the same
name][genshin-repo]. The apex carries its NS delegation as Cloudflare
records.

### Consequences

- Good, because `privacy@dungeon.studio` becomes a Terraform resource
  at no recurring cost with no personal address in public DNS, which
  satisfies drivers 1, 2, and 4.
- Bad, because it fails driver 3. The org layer now spans two providers
  and two credentials, and a Cloudflare API token joins the GCP
  credentials that `just bootstrap` provisions and rotates. DNS
  problems gain a second place to look. The existing account absorbs
  part of that cost, but not the token, the provider version, or the
  split surface.
- Bad, because moving authority is a one-time risk to a live site. The
  DNSSEC chain stays broken until Cloudflare's DS record replaces the
  one at `.studio`, and the zone's existing records have to answer from
  Cloudflare before the nameservers change.
- Neutral, because Cloudflare's proxy, WAF, and redirect rules become
  reachable at the apex. Nothing here needs them, and enabling them
  later is its own decision.
- Neutral, because the `genshin.dungeon.studio` delegation stays
  insecure. Its repository signs the zone, but the apex publishes no DS
  record for it, so the chain of trust already breaks at the
  delegation. Moving the apex neither fixes nor worsens this.

### Confirmation

The zone, its records, and the Email Routing configuration all live in
`terraform/org/`. `dig` shows Cloudflare nameservers for the apex, an
unchanged NS set for `genshin.dungeon.studio`, and a DNSSEC chain that
validates again from `.studio`.

## Pros and Cons of the Options

### Cloudflare Email Routing

- Good, because forwarding to a verified destination is free, with
  [200 destination addresses per account and 200 routing rules per
  domain][limits].
- Good, because the configuration is Terraform-managed through
  `cloudflare_email_routing_settings`, `_address`, `_rule`, and `_dns`
  in provider v5.
- Good, because the account `alunduil-infrastructure` already runs
  `alunduil.com` on the free plan, migrated off these same Cloud DNS
  nameservers. Adding the apex costs a zone and a token scoped to it,
  not a new vendor relationship.
- Bad, because it [requires Cloudflare to be authoritative][enable] for
  the zone. A [partial CNAME setup][partial] does not serve it, so
  choosing it moves the apex off Cloud DNS.

### ForwardEmail on Cloud DNS

- Good, because it needs only MX and TXT records, so the apex stays
  where it is and the records are ordinary `google_dns_record_set`
  resources.
- Bad, because on the free tier the forwarding rule *is* a public TXT
  record, so `privacy@` would publish the address it exists to hide.
  That fails driver 2.
- Bad, because hiding the destination needs a paid plan, which fails
  driver 4.

### ImprovMX on Cloud DNS

- Good, because it keeps the destination out of DNS and the apex where
  it is. It needs no cutover, and the zone carries only MX and SPF
  records.
- Bad, because its Terraform provider is a community project [archived
  in February 2026][improvmx-tf], so driver 1 holds only while an
  unmaintained project keeps working.
- Bad, because nothing else here uses ImprovMX, so driver 3 counts it
  as a new vendor rather than a second zone under an existing one.

## More Information

- [Delegating a subdomain to nameservers outside Cloudflare][delegate] —
  the mechanism the `genshin` NS records use.
- [genshin.dungeon.studio#647][647] — the privacy policy and terms of
  service drafts.

[647]: https://github.com/dungeon-studio/genshin.dungeon.studio/issues/647
[delegate]: https://developers.cloudflare.com/dns/manage-dns-records/how-to/subdomains-outside-cloudflare/
[enable]: https://developers.cloudflare.com/email-routing/get-started/enable-email-routing/
[genshin-repo]: https://github.com/dungeon-studio/genshin.dungeon.studio
[improvmx-tf]: https://github.com/issyl0/terraform-provider-improvmx
[limits]: https://developers.cloudflare.com/email-routing/limits/
[partial]: https://developers.cloudflare.com/dns/zone-setups/partial-setup/
