<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# 1. Host the apex dungeon.studio zone on Cloudflare

## Status

Proposed

## Context

The [monorepo] carries draft privacy policy and terms of service pages
([genshin.dungeon.studio#647][647]). The privacy page records that it
needs a dedicated contact address before the 1.0.0 tag.
`privacy@dungeon.studio` is an apex-domain address, so whatever
delivers it constrains the apex zone.

The apex is already authoritative on Google Cloud DNS
(`ns-cloud-d1..d4.googledomains.com`), and DNSSEC-signed with a DS
record published at `.studio`. It answers with Squarespace A records.
It delegates `genshin.dungeon.studio` by NS to a second Cloud DNS zone
that the monorepo's `core` environment owns. None of it is under
Terraform here yet.

Four requirements:

1. Every piece of configuration lives in Terraform.
2. The forwarding destination stays out of public DNS. An address that
   exists to keep a personal inbox off a legal page cannot publish that
   inbox in a queryable record.
3. Vendors, credentials, and IAM surfaces stay few. Each is another
   token to rotate and another provider to keep current.
4. Recurring cost stays at zero. One forwarding address does not
   justify a subscription.

No option satisfies all four.

**Cloudflare Email Routing** forwards to a verified destination at no
cost, allowing 200 destination addresses per account and 200 routing
rules per domain. The configuration is Terraform-managed through
`cloudflare_email_routing_settings`, `_address`, `_rule`, and `_dns` in
provider v5. It requires Cloudflare to be authoritative for the zone. A
[partial CNAME setup][partial] does not serve it. Choosing it moves the
apex off Cloud DNS.

**ForwardEmail on Cloud DNS** needs only MX and TXT records, so the
apex stays where it is and the records are ordinary
`google_dns_record_set` resources. On the free tier the forwarding rule
*is* a public TXT record, so `privacy@` would publish the address it
exists to hide. Hiding it needs a paid plan. The free tier fails
requirement 2; the paid tier fails requirement 4.

**ImprovMX on Cloud DNS** keeps the destination out of DNS and the apex
where it is. It needs no cutover, and the zone carries only MX and SPF
records. Its Terraform provider is a community project [archived in
February 2026][improvmx-tf], so requirement 1 holds only while an
unmaintained project keeps working. Nothing else here uses ImprovMX, so
requirement 3 counts it as a new vendor rather than a second zone under
an existing one.

Cloudflare is already a vendor here. The account
`alunduil-infrastructure` runs `alunduil.com` on the free plan,
migrated off these same Cloud DNS nameservers. Adding the apex costs a
zone and a token scoped to it, not a new vendor relationship.

## Decision

We will make Cloudflare authoritative for the apex `dungeon.studio`
zone, and manage that zone and its Email Routing configuration from
`terraform/org/` with the Cloudflare provider.

`genshin.dungeon.studio` stays with the monorepo. The apex zone carries
the NS delegation as Cloudflare records. The monorepo keeps ownership of
the subdomain.

## Consequences

`privacy@dungeon.studio` becomes a Terraform resource at no recurring
cost with no personal address in public DNS, satisfying requirements 1,
2, and 4.

It fails requirement 3. The org layer now spans two providers and two
credentials, and a Cloudflare API token joins the GCP credentials that
`just bootstrap` provisions and rotates. DNS problems gain a second
place to look. The existing Cloudflare account absorbs part of that
cost. The token, the provider version, and the split surface remain.

The cutover is a one-time risk to a live site. Moving authority
means disabling DNSSEC at the Squarespace registrar, repointing the
nameservers, and re-enabling DNSSEC with Cloudflare's DS record. The
zone is unsigned between those steps. Run them out of order and it
becomes unresolvable. The Squarespace A records, the `www` CNAME, and
the `genshin` NS delegation all have to exist in Cloudflare, unproxied,
before the nameservers change.

Cloudflare's proxy, WAF, and redirect rules become reachable at the
apex. Nothing here needs them, and enabling them later is its own
decision.

The `genshin.dungeon.studio` delegation stays insecure. The monorepo
signs that zone, but the apex publishes no DS record for it, so the
chain of trust already breaks at the delegation. Moving the apex
neither fixes nor worsens this.

## References

- [Cloudflare Email Routing: enable][enable] — the full-setup
  requirement.
- [Cloudflare Email Routing: limits][limits] — destination and rule
  counts.
- [genshin.dungeon.studio#647][647] — the privacy policy and terms of
  service drafts.
- [Delegating a subdomain to nameservers outside Cloudflare][delegate] —
  the mechanism the `genshin` NS records use.

[647]: https://github.com/dungeon-studio/genshin.dungeon.studio/issues/647
[delegate]: https://developers.cloudflare.com/dns/manage-dns-records/how-to/subdomains-outside-cloudflare/
[enable]: https://developers.cloudflare.com/email-routing/get-started/enable-email-routing/
[improvmx-tf]: https://github.com/issyl0/terraform-provider-improvmx
[limits]: https://developers.cloudflare.com/email-routing/limits/
[monorepo]: https://github.com/dungeon-studio/genshin.dungeon.studio
[partial]: https://developers.cloudflare.com/dns/zone-setups/partial-setup/
