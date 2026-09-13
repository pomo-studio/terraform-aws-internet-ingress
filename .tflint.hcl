plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# The component modules are referenced at main while the blueprint is
# pre-release, so the integration test tracks their current state. Pin each
# source to a release tag before the blueprint itself is tagged.
rule "terraform_module_pinned_source" {
  enabled = false
}
