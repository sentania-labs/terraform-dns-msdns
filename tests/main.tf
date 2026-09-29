# Integration test harness for the DNS module.
# Run from tests/ directory: terraform init && terraform test

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4, < 3.6"
    }
  }
}

variable "hostname" {
  type    = string
  default = "web"
}

variable "zone" {
  type    = string
  default = "example.com."
}

variable "addresses" {
  type    = list(string)
  default = ["10.5.3.7"]
}

variable "ttl" {
  type    = number
  default = 300
}

variable "cnames" {
  type    = list(string)
  default = []
}

module "dns" {
  source    = "../"
  hostname  = var.hostname
  zone      = var.zone
  addresses = var.addresses
  ttl       = var.ttl
  cnames    = var.cnames
}
