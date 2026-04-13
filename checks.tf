check "a_record_ownership" {
  data "dns_a_record_set" "a_lookup" {
    host = "${var.hostname}.${var.zone}"
  }

  assert {
    condition     = dns_a_record_set.this.id != ""
    error_message = <<-EOT
      A record for '${var.hostname}.${var.zone}' already exists in DNS
      with address(es): ${join(", ", data.dns_a_record_set.a_lookup.addrs)}.

      Microsoft DNS uses GSS-TSIG (Kerberos) record ownership. If this record
      was created by a different principal, Terraform will fail with:
        "unexpected acceptor flag is not set"

      To resolve, change record ownership to the Terraform service account
      BEFORE running 'terraform apply':
        1. Delete the record and let Terraform recreate it (dnscmd /RecordDelete)
        2. Update the record's ACL in Active Directory (Set-DnsServerResourceRecord)
        3. Grant the Terraform service account write permission on the record object

      This message will disappear after a successful 'terraform apply'.
    EOT
  }
}
