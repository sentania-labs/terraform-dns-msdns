resource "dns_a_record_set" "this" {
  name      = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl
}
resource "dns_ptr_record" "this" {
  for_each = {
    for r in local.reverse_records :
    "${r.ip}" => r
    if r.zone != null
  }

  zone = each.value.zone
  name = each.value.ptr_name
  ptr  = "${var.hostname}.${var.zone}"
  ttl  = var.ttl
}
resource "dns_cname_record" "aliases" {
  for_each = var.cnames != null ? toset(var.cnames) : toset([])

  zone  = var.zone
  name  = each.value
  cname = "${var.hostname}.${var.zone}"
  ttl   = var.ttl
}
