data "tfe_github_app_installation" "gha_installation" {
  name = var.github_organization
}

data "hcp_organization" "org" {
}

# Moved to a stack
# data "tfe_outputs" "aws_packer_compute" {
#   organization = var.terraform_organization
#   workspace    = "aws-packer-compute"
# }
