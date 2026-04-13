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
  source = "./hostrecord"

  hostname  = "storage.int"
  zone      = "example.com."
  ttl       = 3600

  addresses = [
    "172.16.3.54",
    "172.16.3.53",
    "172.16.3.52",
    "172.16.3.51"
  ]

  cnames = [
    "media.int",
    "backup.int"
  ]
}
```

This results in:

- `storage.example.com` → multiple A records
- PTR records in `16.172.in-addr.arpa.`
- CNAMEs:
  - `media.example.com`
  - `backup.example.com`

---

## Variables

| Name       | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `hostname` | `string` | yes | Short hostname (no zone suffix) |
| `zone` | `string` | yes | Forward DNS zone (must end with `.`) |
| `addresses` | `list(string)` | yes | IPv4 addresses |
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

PTR **names** are always:
```
<last-octet>.<third-octet>
```

Example:
```
172.27.8.11 → 11.8.27.172.in-addr.arpa.
```

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
- **Record already exists (first plan):** A warning is shown with the existing
  addresses and remediation steps.
- **After successful apply:** No warning on subsequent plans.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_dns"></a> [dns](#requirement\_dns) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_dns"></a> [dns](#provider\_dns) | ~> 3.4 |

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
| <a name="input_ttl"></a> [ttl](#input\_ttl) | DNS record TTL in seconds | `number` | `300` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Forward DNS zone, must end with a trailing dot (e.g. "example.com.") | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_addresses"></a> [addresses](#output\_addresses) | List of IPv4 addresses registered for this host |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fully qualified domain name of the A record (hostname + zone) |
| <a name="output_ptr_records"></a> [ptr\_records](#output\_ptr\_records) | Map of IP address to its PTR record name within the reverse zone |
<!-- END_TF_DOCS -->