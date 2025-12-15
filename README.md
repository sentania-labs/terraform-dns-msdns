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

## Limitations

- IPv6 not currently supported
- Non-RFC1918 reverse zones are ignored

---

## License

MIT
