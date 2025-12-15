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

  reverse_records = [
    for o in local.ip_objects : {
      ip = o.ip

      # PTR name is always last two octets
      ptr_name = "${o.o4}.${o.o3}"

      zone = (
        o.o1 == 10 ? "10.in-addr.arpa." :
        o.o1 == 192 && o.o2 == 168 ? "168.192.in-addr.arpa." :
        o.o1 == 172 && o.o2 >= 16 && o.o2 <= 31 ?
        "${o.o2}.172.in-addr.arpa." :
        null
      )
    }
  ]
}
