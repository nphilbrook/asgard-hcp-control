resource "tfe_policy_set" "cis" {
  name          = "CIS-Policy-Set-for-AWS-Terraform"
  description   = "The pre-written CIS policies for AWS Terraform"
  kind          = "sentinel"
  agent_enabled = "true"

  vcs_repo {
    # may go back for this fork later
    # identifier     = "${var.github_organization}/policy-library-CIS-Policy-Set-for-AWS-Terraform"
    identifier                 = "hashicorp/policy-library-CIS-Policy-Set-for-AWS-Terraform"
    branch                     = "release/1.0.1"
    github_app_installation_id = data.tfe_github_app_installation.gha_installation.id
  }
}

resource "tfe_policy_set" "andre" {
  name          = "andrefaria-examples"
  description   = "Some example useful policies from your local friendly SE"
  kind          = "sentinel"
  agent_enabled = "true"

  vcs_repo {
    # may go back for this fork later
    # identifier     = "${var.github_organization}/policy-library-sentinel-terraform-hcp"
    identifier                 = "andrefaria24/policy-library-sentinel-terraform-hcp"
    github_app_installation_id = data.tfe_github_app_installation.gha_installation.id
  }
}

resource "tfe_policy_set_parameter" "allowed_providers" {
  key = "allowed_providers"
  value = jsonencode([
    "registry.terraform.io/hashicorp/aws",
    "registry.terraform.io/hashicorp/tfe",
    "registry.terraform.io/hashicorp/random",
    "registry.terraform.io/hashicorp/hcp"
  ])
  policy_set_id = tfe_policy_set.andre.id
}

resource "tfe_policy_set_parameter" "tf_allowed_versions" {
  key = "tf_allowed_versions"
  value = jsonencode([
    "1.13.3",
    "1.13.0",
    "1.12.2",
    "1.12.1",
    "1.12.0",
    "1.11.4",
    "1.11.3",
    "1.11.2",
    "1.11.1",
    "1.11.0",
  ])
  policy_set_id = tfe_policy_set.andre.id
}

resource "tfe_policy_set_parameter" "private_registry_allowed_organizations" {
  key = "organizations"
  value = jsonencode([
    var.terraform_organization
  ])
  policy_set_id = tfe_policy_set.andre.id
}
