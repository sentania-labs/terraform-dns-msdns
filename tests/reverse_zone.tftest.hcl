# Reverse zone (PTR) tests for RFC1918 ranges.
# The root config (tests/main.tf) defines variables that pass through
# to the module. variables {} in each run block overrides those,
# letting us test many scenarios from one config file.

run "ptr_10_network_single" {
  command = plan
  variables {
    hostname  = "web"
    zone      = "example.com."
    addresses = ["10.5.3.7"]
  }

  assert {
    condition     = module.dns.ptr_records["10.5.3.7"] == "7.3.5.10.in-addr.arpa."
    error_message = "10.x.x.x should produce 7.3.5.10.in-addr.arpa."
  }
}

run "ptr_10_network_multi" {
  command = plan
  variables {
    hostname  = "db"
    zone      = "example.com."
    addresses = ["10.0.0.1", "10.255.255.254"]
  }

  assert {
    condition     = module.dns.ptr_records["10.0.0.1"] == "1.0.0.10.in-addr.arpa."
    error_message = "10.0.0.1 should produce 1.0.0.10.in-addr.arpa."
  }

  assert {
    condition     = module.dns.ptr_records["10.255.255.254"] == "254.255.255.10.in-addr.arpa."
    error_message = "10.255.255.254 should produce 254.255.255.10.in-addr.arpa."
  }

  assert {
    condition     = length(module.dns.ptr_records) == 2
    error_message = "Two 10.x.x.x addresses should yield two PTR records."
  }
}

run "ptr_192168_single" {
  command = plan
  variables {
    hostname  = "fileserver"
    zone      = "example.com."
    addresses = ["192.168.1.50"]
  }

  assert {
    condition     = module.dns.ptr_records["192.168.1.50"] == "50.1.168.192.in-addr.arpa."
    error_message = "192.168.1.50 should produce 50.1.168.192.in-addr.arpa."
  }
}

run "ptr_192168_multi" {
  command = plan
  variables {
    hostname  = "cache"
    zone      = "example.com."
    addresses = ["192.168.0.1", "192.168.255.254"]
  }

  assert {
    condition     = module.dns.ptr_records["192.168.0.1"] == "1.0.168.192.in-addr.arpa."
    error_message = "192.168.0.1 should produce 1.0.168.192.in-addr.arpa."
  }

  assert {
    condition     = length(module.dns.ptr_records) == 2
    error_message = "Two 192.168.x.x addresses should yield two PTR records."
  }
}

run "ptr_17216_base" {
  command = plan
  variables {
    hostname  = "app"
    zone      = "example.com."
    addresses = ["172.16.0.10"]
  }

  assert {
    condition     = module.dns.ptr_records["172.16.0.10"] == "10.0.16.172.in-addr.arpa."
    error_message = "172.16.0.10 should produce 10.0.16.172.in-addr.arpa."
  }
}

run "ptr_17231_edge" {
  command = plan
  variables {
    hostname  = "lb"
    zone      = "example.com."
    addresses = ["172.31.255.1"]
  }

  assert {
    condition     = module.dns.ptr_records["172.31.255.1"] == "1.255.31.172.in-addr.arpa."
    error_message = "172.31.255.1 should produce 1.255.31.172.in-addr.arpa."
  }
}

run "ptr_172_mid_range" {
  command = plan
  variables {
    hostname  = "monitor"
    zone      = "example.com."
    addresses = ["172.20.10.5"]
  }

  assert {
    condition     = module.dns.ptr_records["172.20.10.5"] == "5.10.20.172.in-addr.arpa."
    error_message = "172.20.10.5 should produce 5.10.20.172.in-addr.arpa."
  }
}

run "ptr_17215_not_rfc1918" {
  command = plan
  variables {
    hostname  = "web"
    zone      = "example.com."
    addresses = ["172.15.0.1"]
  }

  assert {
    condition     = length(module.dns.ptr_records) == 0
    error_message = "172.15.x.x is outside RFC1918 172.16/12; no PTR record expected."
  }
}

run "ptr_17232_not_rfc1918" {
  command = plan
  variables {
    hostname  = "web"
    zone      = "example.com."
    addresses = ["172.32.0.1"]
  }

  assert {
    condition     = length(module.dns.ptr_records) == 0
    error_message = "172.32.x.x is outside RFC1918 172.16/12; no PTR record expected."
  }
}

run "ptr_public_no_ptr" {
  command = plan
  variables {
    hostname  = "cdn"
    zone      = "example.com."
    addresses = ["8.8.8.8"]
  }

  assert {
    condition     = length(module.dns.ptr_records) == 0
    error_message = "Public IP 8.8.8.8 should produce no PTR record."
  }
}

run "ptr_mixed_private_public" {
  command = plan
  variables {
    hostname  = "hybrid"
    zone      = "example.com."
    addresses = ["10.1.1.1", "8.8.4.4", "192.168.10.20"]
  }

  assert {
    condition     = module.dns.ptr_records["10.1.1.1"] == "1.1.1.10.in-addr.arpa."
    error_message = "10.1.1.1 should produce PTR."
  }

  assert {
    condition     = module.dns.ptr_records["192.168.10.20"] == "20.10.168.192.in-addr.arpa."
    error_message = "192.168.10.20 should produce PTR."
  }

  assert {
    condition     = contains(keys(module.dns.ptr_records), "8.8.4.4") == false
    error_message = "8.8.4.4 is public; should not be in module.dns.ptr_records."
  }

  assert {
    condition     = length(module.dns.ptr_records) == 2
    error_message = "Mixed private+public: only 2 PTR records expected."
  }
}

run "a_record_single_fqdn" {
  command = plan
  variables {
    hostname  = "web"
    zone      = "example.com."
    addresses = ["10.0.0.5"]
  }

  assert {
    condition     = module.dns.fqdn == "web.example.com."
    error_message = "FQDN should be web.example.com."
  }

  assert {
    condition     = toset(module.dns.addresses) == toset(["10.0.0.5"])
    error_message = "A record should have the single specified address."
  }
}

run "a_record_multi" {
  command = plan
  variables {
    hostname  = "storage"
    zone      = "example.com."
    addresses = ["172.16.3.54", "172.16.3.53", "172.16.3.52"]
  }

  assert {
    condition     = toset(module.dns.addresses) == toset(["172.16.3.54", "172.16.3.53", "172.16.3.52"])
    error_message = "A record set should match the provided addresses."
  }
}

run "a_record_custom_zone" {
  command = plan
  variables {
    hostname  = "db"
    zone      = "corp.internal."
    addresses = ["10.10.0.2"]
  }

  assert {
    condition     = module.dns.fqdn == "db.corp.internal."
    error_message = "FQDN should include the zone domain."
  }
}
