locals {
  ip_objects = [
    for ip in var.addresses : {
      ip = ip
      o1 = tonumber(split(".", ip)[0])
      o2 = tonumber(split(".", ip)[1])
      o3 = tonumber(split(".", ip)[2])
      o4 = tonumber(split(".", ip)[3])
    }
  ]

  # Reverse zone per address, aligned with var.addresses by position. An
  # explicit var.reverse_zones is used as given, so the PTR key set depends
  # only on the caller's list and never on the address values (which may be
  # unknown at plan time). Without it the zone is derived from RFC1918 ranges,
  # which requires the addresses to be known at plan time.
  derived_zones = [
    for o in local.ip_objects :
    o.o1 == 10 ? "10.in-addr.arpa." : o.o1 == 192 && o.o2 == 168 ? "168.192.in-addr.arpa." : o.o1 == 172 && o.o2 >= 16 && o.o2 <= 31 ? "${o.o2}.172.in-addr.arpa." : null
  ]

  reverse_zones = var.reverse_zones != null ? var.reverse_zones : local.derived_zones

  # Full reverse name of each address, e.g. 7.3.5.10.in-addr.arpa.
  reverse_names = [
    for o in local.ip_objects : "${o.o4}.${o.o3}.${o.o2}.${o.o1}.in-addr.arpa."
  ]

  # Keyed by position in var.addresses; only the zone list decides which keys exist.
  ptr_records = {
    for idx, zone in local.reverse_zones :
    idx => {
      zone = zone
      # PTR name relative to the zone, e.g. 7.3.5 within 10.in-addr.arpa.
      name = trimsuffix(local.reverse_names[idx], ".${zone}")
    } if zone != null
  }
}
