resource "dns_a_record_set" "this" {
  name      = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl
}

resource "dns_ptr_record" "this" {
  for_each = {
    for idx, addr in var.addresses : idx => addr if try(local.ptr_zones[addr], null) != null
  }

  zone = local.ptr_zones[each.value]
  name = local.ptr_names[each.value]
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
