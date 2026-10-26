# DNS Host Record Module

This Terraform module manages **forward (A), reverse (PTR), and optional CNAME records** using the `dns` provider.

It is designed for environments like **Active Directory DNS or BIND** where:
- Forward records live in a standard zone (e.g. `example.com.`)
- Reverse zones follow RFC1918 conventions
- Dynamic updates are authenticated (GSS-TSIG or TSIG)

---

## What This Module Creates

For a single logical host:

- **A record set**
  - One hostname
  - One or more IPv4 addresses
- **PTR records**
  - Automatically derived from each IPv4 address
  - Supports:
    - `10.0.0.0/8`
    - `172.16.0.0/12`
    - `192.168.0.0/16`
- **Optional CNAME records**
  - Zero or more aliases pointing to the canonical hostname

---

## Example Usage

```hcl
module "storage" {
  source  = "sentania-labs/msdns/dns"
  version = "~> 0.2"

  hostname  = "storage"
  zone      = "example.com."
  ttl       = 3600

  addresses = [
    "172.16.3.54",
    "172.16.3.53",
    "172.16.3.52",
    "172.16.3.51"
  ]

  cnames = [
    "media",
    "backup"
  ]
}
```

This results in:

- `storage.example.com` → multiple A records
- PTR records in `16.172.in-addr.arpa.`
- CNAMEs:
  - `media.example.com` → `storage.example.com`
  - `backup.example.com` → `storage.example.com`

---

## Variables

| Name       | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `hostname` | `string` | yes | Short hostname (no zone suffix) |
| `zone` | `string` | yes | Forward DNS zone (must end with `.`) |
| `addresses` | `list(string)` | yes | IPv4 addresses |
| `reverse_zones` | `list(string)` | no | Reverse zone per address, by position; `null` entry = no PTR (default: derived from RFC1918 range) |
| `ttl` | `number` | no | Record TTL (default: 300) |
| `cnames` | `list(string)` | no | Optional aliases |

---

## Reverse DNS Logic

PTR records are generated automatically:

| Address Range | Reverse Zone |
|--------------|--------------|
| `10.x.x.x` | `10.in-addr.arpa.` |
| `192.168.x.x` | `168.192.in-addr.arpa.` |
| `172.16–31.x.x` | `<second-octet>.172.in-addr.arpa.` |

PTR **names** are the reversed address relative to its reverse zone
(`<o4>.<o3>.<o2>` in `10.in-addr.arpa.`, `<o4>.<o3>` in the 192.168 and 172.16/12 zones).

Example:
```
172.27.8.11 → 11.8.27.172.in-addr.arpa.
```

### Addresses that are only known after apply

PTR records are keyed by position in `addresses`, so Terraform needs to know
*which* addresses get a PTR record at plan time. When an address comes from
another resource (unknown until apply), the zone can't be derived from it, so
pass `reverse_zones` with one entry per address (`null` for no PTR):

```hcl
module "vm" {
  source = "sentania-labs/msdns/dns"

  hostname      = "vm01"
  zone          = "example.com."
  addresses     = [vsphere_virtual_machine.vm.default_ip_address]
  reverse_zones = ["10.in-addr.arpa."]
}
```

Without `reverse_zones`, addresses must be known at plan time.

---

## Upgrading from 0.6.x

0.7 keys `dns_ptr_record.this` by position in `addresses` (`"0"`, `"1"`, ...)
instead of by IP address. Upgrading therefore plans a **destroy and recreate of
every PTR record** (a brief gap in reverse resolution, and the record is
re-owned by the Terraform principal). That is safe to accept as a one-time
change. To avoid it, add one `moved` block per address in the calling
configuration (a module cannot write these for caller-specific IPs):

```hcl
moved {
  from = module.storage.dns_ptr_record.this["172.16.3.54"]
  to   = module.storage.dns_ptr_record.this["0"]
}
```

`"0"` is the address's position in `addresses`; skip addresses outside
RFC1918, which never had a PTR record. Reordering `addresses` later moves
the records the same way, so append new addresses at the end.

---

## Authentication Notes

This module assumes the `dns` provider is already configured.

Common setups:
- **Active Directory DNS**
  - GSS-TSIG (Kerberos)
- **BIND**
  - TSIG key authentication

Ensure:
- The update principal has permissions on both forward and reverse zones
- The server specified in the provider matches the DNS SPN (for GSS-TSIG)

---

## Design Goals

- One module = one logical host
- Idempotent DNS ownership
- No surprises with PTR math
- Friendly to GitOps and CI/CD

---

## Pre-Existing Record Detection

This module includes a `check` block that queries DNS during `terraform plan`
to detect A records that already exist. This helps catch **GSS-TSIG ownership
conflicts** before `terraform apply` fails with the cryptic error:

```
unexpected acceptor flag is not set: expecting a token from the acceptor, not in the initiator
```

### When warnings appear

- **New record (no pre-existing):** No warning. The DNS lookup returns NXDOMAIN
  and the check is silently skipped.
- **Record exists with different addresses:** A warning is shown with the
  existing and requested addresses, plus remediation steps.
- **Record exists with matching addresses:** No warning. If the record was
  created by a different Kerberos principal, apply may still fail — see the
  remediation steps below.
- **After successful apply:** No warning on subsequent plans (addresses match).

### Why this happens

Microsoft DNS enforces record ownership via Kerberos (GSS-TSIG). Only the
principal that created a record can update it. When Terraform's service account
tries to manage a record created by a different principal, the DNS server
rejects the update.

### How to fix it

Before running `terraform apply`, transfer ownership using one of:

1. **Delete and recreate** -- remove the record (e.g. `dnscmd /RecordDelete`)
   and let Terraform create it with the correct ownership
2. **Update the ACL** -- use `Set-DnsServerResourceRecord` in PowerShell to
   grant the Terraform service account write permission
3. **AD delegation** -- grant the service account broader write permission on
   the DNS zone's AD objects

### Scope

Only the **A record** is checked. PTR and CNAME records cannot be checked
individually because Terraform `check` blocks do not support `for_each`. If the
A record check warns, related PTR/CNAME records likely have the same ownership
issue.

---

## Known Issues

### hashicorp/dns provider 3.6.0 breaks GSS-TSIG with Windows AD DNS

Provider version 3.6.0 (released 2026-05-12) upgraded its `bodgit/tsig`
dependency from 1.2.2 to 1.3.0. The new version refactored GSSAPI into
a wrapper library (`bodgit/gssapi`) that enforces strict RFC 4121 MIC
token flag validation. Windows AD DNS servers don't always set the
`SentByAcceptor` flag in their response tokens, causing all DNS writes
to fail with:

```
unexpected acceptor flag is not set: expecting a token from the acceptor,
not in the initiator
```

DNS reads (plan/refresh) still work — only writes (apply) are affected.

This module constrains the provider to `>= 3.4, < 3.6` until the
upstream fix lands. Tracked in:
- [bodgit/tsig #178](https://github.com/bodgit/tsig/issues/178)
- [bodgit/tsig #54](https://github.com/bodgit/tsig/issues/54)

## Limitations

- IPv6 not currently supported
- Non-RFC1918 reverse zones are ignored

---

## License

MIT

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_dns"></a> [dns](#requirement\_dns) | >= 3.4, < 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_dns"></a> [dns](#provider\_dns) | 3.5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [dns_a_record_set.this](https://registry.terraform.io/providers/hashicorp/dns/latest/docs/resources/a_record_set) | resource |
| [dns_cname_record.aliases](https://registry.terraform.io/providers/hashicorp/dns/latest/docs/resources/cname_record) | resource |
| [dns_ptr_record.this](https://registry.terraform.io/providers/hashicorp/dns/latest/docs/resources/ptr_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addresses"></a> [addresses](#input\_addresses) | IPv4 addresses for this host | `list(string)` | n/a | yes |
| <a name="input_cnames"></a> [cnames](#input\_cnames) | CNAME aliases to associate with this record (all within the same zone) | `list(string)` | `[]` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Short hostname without zone suffix or trailing dot (e.g. "storage") | `string` | n/a | yes |
| <a name="input_reverse_zones"></a> [reverse\_zones](#input\_reverse\_zones) | Reverse zone for each entry of addresses, matched by position; null entry = no PTR. Needed when addresses are unknown until apply. | `list(string)` | `null` | no |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | DNS record TTL in seconds | `number` | `300` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Forward DNS zone, must end with a trailing dot (e.g. "example.com.") | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_addresses"></a> [addresses](#output\_addresses) | List of IPv4 addresses registered for this host |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fully qualified domain name of the A record (hostname + zone) |
| <a name="output_ptr_names"></a> [ptr\_names](#output\_ptr\_names) | Map of position in addresses to the PTR record name within its reverse zone; keys are known at plan time |
| <a name="output_ptr_records"></a> [ptr\_records](#output\_ptr\_records) | Map of IP address to its PTR record name within the reverse zone |
<!-- END_TF_DOCS -->