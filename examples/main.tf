module "server_dns" {
  source = "../"

  hostname  = "test"
  zone      = "example.com"
  addresses = ["172.31.1.2", "172.31.1.3"]
  ttl       = "3600"
  cnames    = ["alias", "www"] #CNMAES are presumed to belong to the same parent zone
}
