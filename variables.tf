variable "hostname" {
  type        = string
  description = "Short hostname, e.g. storage.int"
}

variable "zone" {
  type        = string
  description = "Forward DNS zone, e.g. sentania.net"
}

variable "addresses" {
  type        = list(string)
  description = "IPv4 addresses for this host"

  validation {
    condition = alltrue([
      for ip in var.addresses :
      can(regex(
        "^([0-9]{1,3}\\.){3}[0-9]{1,3}$",
        ip
      ))
    ])
    error_message = "All addresses must be valid IPv4 strings."
  }
}


variable "ttl" {
  type    = number
  default = 300
}

variable "cnames" {
  type        = list(string)
  description = "cnames to asscoiate with this record"
  default     = []
}