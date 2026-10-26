resource "dns_a_record_set" "this" {
  name      = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl
}

resource "dns_ptr_record" "this" {
  for_each = local.ptr_records

  zone = each.value.zone
  name = each.value.name
  ptr  = "${var.hostname}.${var.zone}"
  ttl  = var.ttl
}

resource "dns_cname_record" "aliases" {
  for_each = toset(coalesce(var.cnames, []))

  zone  = var.zone
  name  = each.value
  cname = "${var.hostname}.${var.zone}"
  ttl   = var.ttl
}
