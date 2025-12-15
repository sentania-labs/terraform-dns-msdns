terraform {
  required_version = ">= 1.4.0"

  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4"
    }
  }
}
