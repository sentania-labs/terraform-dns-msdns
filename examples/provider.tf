provider "dns" {
  update {
    server = "dns1.example.com"
    gssapi {
      realm    = "EXAMPLE.COM"
      username = "serviceID"
      password = "passwd"
    }
  }
}
