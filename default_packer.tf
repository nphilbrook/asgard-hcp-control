resource "hcp_packer_bucket" "bastion" {
  project_id = data.hcp_project.default.resource_id
  name       = "bastion"
}

resource "hcp_packer_channel" "bastion_dev" {
  project_id  = data.hcp_project.default.resource_id
  name        = "dev"
  bucket_name = hcp_packer_bucket.bastion.name
}

# This is the SP to actually build images from my mac
# I'll need to generate a Client Secret for this, will do in console
resource "hcp_service_principal" "packer_default" {
  name   = "packer-local"
  parent = data.hcp_project.default.resource_name
}

resource "hcp_project_iam_binding" "packer_default_contrib" {
  principal_id = hcp_service_principal.packer_default.resource_id
  project_id   = data.hcp_project.default.resource_id
  role         = "roles/contributor"
}

resource "hcp_service_principal" "bastion_tf_read" {
  name   = "bastion-tf-hcp-read"
  parent = data.hcp_project.default.resource_name
}

# Scope this principal to only be able to read from the project
# Note that you can't go finer-grained than project level
# or the provider authentication will not work
resource "hcp_project_iam_binding" "bastion_tf_read" {
  principal_id = hcp_service_principal.bastion_tf_read.resource_id
  project_id   = data.hcp_project.default.resource_id
  role         = "roles/viewer"
}

resource "hcp_iam_workload_identity_provider" "bastion_tf_read_provider" {
  name              = "bastion-hcp-tf-read-provider"
  service_principal = hcp_service_principal.bastion_tf_read.resource_name
  description       = "Allow this org on HCP TF to read HCP Packer artifact versions"

  oidc = {
    issuer_uri        = "https://app.terraform.io"
    allowed_audiences = [local.hcp_audience]
  }

  # Allow workloads running from any project in the HCP TF Organization
  conditional_access = "jwt_claims.sub matches `^organization:${var.terraform_organization}:.+`"
}

resource "tfe_variable_set" "bastion_workspaces" {
  name   = "hcp-auth-bastion-workspaces"
  global = false
}

# Required environment variable to enable HCP dynamic credentials
resource "tfe_variable" "bastion_hcp_provider_auth" {
  variable_set_id = tfe_variable_set.bastion_workspaces.id
  key             = "TFC_HCP_PROVIDER_AUTH"
  value           = "true"
  category        = "env"
  description     = "Enable HCP dynamic credentials authentication"
}

# Required environment variable for the workload identity provider resource name
resource "tfe_variable" "bastion_hcp_run_provider_resource_name" {
  variable_set_id = tfe_variable_set.bastion_workspaces.id
  key             = "TFC_HCP_RUN_PROVIDER_RESOURCE_NAME"
  value           = hcp_iam_workload_identity_provider.bastion_tf_read_provider.resource_name
  category        = "env"
  description     = "Resource name of the Bastion workload identity provider for HCP authentication. "
}

resource "tfe_variable" "bastion_hcp_run_provider_audience" {
  variable_set_id = tfe_variable_set.bastion_workspaces.id
  key             = "TFC_HCP_WORKLOAD_IDENTITY_AUDIENCE"
  value           = local.hcp_audience
  category        = "env"
  description     = "Audience to use in the OIDC"
}

resource "tfe_workspace_variable_set" "bastion_workspaces" {
  workspace_id    = data.tfe_workspace.aws_vault_hvd.id
  variable_set_id = tfe_variable_set.bastion_workspaces.id
}