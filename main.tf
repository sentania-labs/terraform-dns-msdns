resource "dns_a_record_set" "this" {
  name      = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl

  lifecycle {
    precondition {
      condition     = var.reverse_zones == null ? true : length(var.reverse_zones) == length(var.addresses)
      error_message = "reverse_zones must have exactly one entry per address (${length(var.addresses)} addresses given)."
    }
  }
}

resource "dns_ptr_record" "this" {
  for_each = local.ptr_records

  zone = each.value.zone
  name = each.value.name
  ptr  = "${var.hostname}.${var.zone}"
  ttl  = var.ttl

  lifecycle {
    precondition {
      condition     = endswith(local.reverse_names[tonumber(each.key)], ".${each.value.zone}")
      error_message = "Address ${var.addresses[tonumber(each.key)]} is not in reverse zone ${each.value.zone}."
    }
  }
}

resource "dns_cname_record" "aliases" {
  for_each = toset(coalesce(var.cnames, []))

  zone  = var.zone
  name  = each.value
  cname = "${var.hostname}.${var.zone}"
  ttl   = var.ttl
}
