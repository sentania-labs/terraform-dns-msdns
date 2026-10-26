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

variable "reverse_zones" {
  type    = list(string)
  default = null
}

variable "computed_address" {
  type        = bool
  description = "Take the address from a resource attribute that is unknown until apply"
  default     = false
}

# terraform_data.output is unknown at plan time while the input is.
resource "terraform_data" "computed_ip" {
  input = timestamp()
}

locals {
  addresses = var.computed_address ? [terraform_data.computed_ip.output] : var.addresses
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
  source        = "../"
  hostname      = var.hostname
  zone          = var.zone
  addresses     = local.addresses
  reverse_zones = var.reverse_zones
  ttl           = var.ttl
  cnames        = var.cnames
}
