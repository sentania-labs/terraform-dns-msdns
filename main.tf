resource "dns_a_record_set" "this" {
  name      = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl
}

resource "dns_ptr_record" "this" {
  for_each = {
    for idx, addr in var.addresses :
    idx => addr if (addr =~ "^10\\..*" || addr =~ "^192\\.168\\..*" || addr =~ "^172\\.(1[6-9]|2\\d|3[01])\\..*")
  }

  zone = each.value =~ "^10\\..*" ? "10.in-addr.arpa." :
         each.value =~ "^192\\.168\\..*" ? "168.192.in-addr.arpa." :
         each.value =~ "^172\\.(1[6-9]|2\\d|3[01])\\..*" ? "${split(\".\", each.value)[1]}.172.in-addr.arpa." :
         null
  name = each.value =~ "^10\\..*" ? "${split(\".\", each.value)[3]}.${split(\".\", each.value)[2]}.${split(\".\", each.value)[1]}" :
         each.value =~ "^192\\.168\\..*" ? "${split(\".\", each.value)[3]}.${split(\".\", each.value)[2]}" :
         each.value =~ "^172\\.(1[6-9]|2\\d|3[01])\\..*" ? "${split(\".\", each.value)[3]}.${split(\".\", each.value)[2]}" :
         null
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
