variable "hostname" {
  type        = string
  description = "Short hostname without zone suffix or trailing dot (e.g. \"storage\")"

  validation {
    condition     = !endswith(var.hostname, ".")
    error_message = "hostname must not end with a trailing dot."
  }
}

variable "zone" {
  type        = string
  description = "Forward DNS zone, must end with a trailing dot (e.g. \"example.com.\")"

  validation {
    condition     = endswith(var.zone, ".")
    error_message = "zone must end with a trailing dot (e.g. \"example.com.\")."
  }
}

variable "addresses" {
  type        = list(string)
  description = "IPv4 addresses for this host"

  validation {
    condition = alltrue([
      for ip in var.addresses :
      can(cidrnetmask("${ip}/32"))
    ])
    error_message = "All addresses must be valid IPv4 strings (each octet 0-255)."
  }
}

variable "reverse_zones" {
  type        = list(string)
  description = <<-EOT
    Reverse zone for each entry of addresses, matched by position (e.g. "10.in-addr.arpa."),
    each ending with a trailing dot. Use null for an address that should get no PTR record.
    Required when addresses are not known until apply (for example an address taken from
    another resource), because the set of PTR records must be known at plan time. When
    null, the zone is derived from the RFC1918 range of each address, which needs known addresses.
  EOT
  default     = null

  validation {
    condition = var.reverse_zones == null ? true : alltrue([
      for z in var.reverse_zones : z == null ? true : endswith(z, ".in-addr.arpa.")
    ])
    error_message = "Each reverse_zones entry must be null or a zone ending in \".in-addr.arpa.\"."
  }
}

variable "ttl" {
  type        = number
  description = "DNS record TTL in seconds"
  default     = 300
}

variable "cnames" {
  type        = list(string)
  description = "CNAME aliases to associate with this record (all within the same zone)"
  default     = []
}
