# TFLint configuration for terraform-dns-msdns module
# The terraform_required_version warning is disabled because it triggers
# on test harness files that don't need it, even though they do define it.

rule "terraform_required_version" {
  enabled = false
}
