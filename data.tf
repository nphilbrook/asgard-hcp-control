data "tfe_github_app_installation" "gha_installation" {
  name = var.github_organization
}

data "hcp_organization" "org" {
}

data "hcp_project" "default" {
  project = "bbb3c5e5-262e-4171-8747-bf5da61f75d1"
}

data "tfe_workspace" "aws_vault_hvd" {
  name = "aws-vault-hvd"
}

# Moved to a stack
# data "tfe_outputs" "aws_packer_compute" {
#   organization = var.terraform_organization
#   workspace    = "aws-packer-compute"
# }
