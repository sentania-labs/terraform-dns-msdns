output "fqdn" {
  value = dns_a_record_set.this.name
}

output "addresses" {
  value = join(",", dns_a_record_set.this.addresses)
}

output "ptr_records" {
  value = {
    for k, v in dns_ptr_record.this :
    k => v.zone
  }
}
