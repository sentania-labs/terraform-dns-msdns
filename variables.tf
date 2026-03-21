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
