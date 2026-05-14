terraform {
  required_version = ">= 1.5.0"

  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4, < 3.6"
    }
  }
}
