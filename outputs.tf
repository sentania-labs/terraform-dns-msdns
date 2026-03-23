output "fqdn" {
  description = "Fully qualified domain name of the A record (hostname + zone)"
  value       = "${dns_a_record_set.this.name}.${var.zone}"
}

output "addresses" {
  description = "List of IPv4 addresses registered for this host"
  value       = dns_a_record_set.this.addresses
}

output "ptr_records" {
  description = "Map of IP address to its PTR record name within the reverse zone"
  value = {
    for k, v in dns_ptr_record.this :
    k => "${v.name}.${v.zone}"
  }
}
