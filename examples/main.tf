locals {
  hostname  = "test"
  zone      = "example.com."
  addresses = ["172.31.1.2", "172.31.1.3"]
}

module "server_dns" {
  source = "../"

  hostname  = local.hostname
  zone      = local.zone
  addresses = local.addresses
  ttl       = 3600
  cnames    = ["alias", "www"] # CNAMEs are presumed to belong to the same parent zone
}
