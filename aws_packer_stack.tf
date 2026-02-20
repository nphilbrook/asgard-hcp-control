resource "tfe_project" "packer" {
  name = "aws-packer-compute"
}

resource "tfe_stack" "aws_packer" {
  name                = "aws-asgard-packer-compute"
  project_id          = tfe_project.packer.id
  speculative_enabled = true
  vcs_repo {
    github_app_installation_id = data.tfe_github_app_installation.gha_installation.id
    identifier                 = "${var.github_organization}/aws-asgard-packer-compute"
  }
}

module "aws_oidc_compute" {
  source                 = "app.terraform.io/philbrook/tfe-oidc/aws"
  version                = "1.0.0"
  mode                   = "project"
  terraform_organization = var.terraform_organization
  tf_project_name        = tfe_project.packer.name
  tf_project_id          = tfe_project.packer.id
  aws_policy_arn         = aws_iam_policy.packer_tf_policy.arn
}

# HCP Service Principal for this workspace
# Just needs read perms to access Packer bucket/channel versions
resource "hcp_service_principal" "packer_tf" {
  name   = "hcp-tf-packer-read"
  parent = hcp_project.admin.resource_name
}

resource "hcp_project_iam_binding" "packer_tf_read" {
  principal_id = hcp_service_principal.packer_tf.resource_id
  project_id   = hcp_project.admin.resource_id
  role         = "roles/viewer"
}

resource "hcp_iam_workload_identity_provider" "packer_tf_provider" {
  name              = "hcp-tf-packer"
  service_principal = hcp_service_principal.packer_tf.resource_name
  description       = "Allow this workspace on HCP TF to view HCP resources (packer buckets)"

  oidc = {
    issuer_uri        = "https://app.terraform.io"
    allowed_audiences = [local.hcp_audience]
  }

  # Only allow workloads running from the Packer project
  conditional_access = "jwt_claims.sub matches `^organization:${var.terraform_organization}:project:${tfe_project.packer.name}:.+`"
}

resource "tfe_variable_set" "packer_hcp_auth" {
  name              = "hcp-auth-aws-packer"
  description       = "HCP auth variables for the packer project"
  global            = "false"
  parent_project_id = tfe_project.packer.id
}

resource "tfe_project_variable_set" "packer_hcp_auth" {
  project_id      = tfe_project.packer.id
  variable_set_id = tfe_variable_set.packer_hcp_auth.id
}

# Required environment variable to enable HCP dynamic credentials
resource "tfe_variable" "hcp_provider_auth_packer" {
  variable_set_id = tfe_variable_set.packer_hcp_auth.id

  key         = "TFC_HCP_PROVIDER_AUTH"
  value       = "true"
  category    = "env"
  description = "Enable HCP dynamic credentials authentication"
}

# Required environment variable for the workload identity provider resource name
resource "tfe_variable" "hcp_run_provider_resource_name_packer" {
  variable_set_id = tfe_variable_set.packer_hcp_auth.id

  key         = "TFC_HCP_RUN_PROVIDER_RESOURCE_NAME"
  value       = hcp_iam_workload_identity_provider.packer_tf_provider.resource_name
  category    = "env"
  description = "Resource name of the workload identity provider for HCP authentication"
}

resource "tfe_variable" "packer_hcp_run_provider_audience" {
  variable_set_id = tfe_variable_set.packer_hcp_auth.id
  key             = "TFC_HCP_WORKLOAD_IDENTITY_AUDIENCE"
  value           = local.hcp_audience
  category        = "env"
  description     = "Audience to use in the OIDC"
}
