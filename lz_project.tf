resource "tfe_project" "lz_admin" {
  name = "lz-admin"
}

resource "hcp_service_principal" "lz_tf_deploy" {
  name   = "lz-hcp-tf-deploy"
  parent = data.hcp_organization.org.resource_name
}

resource "hcp_organization_iam_binding" "lz_tf_deploy_admin" {
  principal_id = hcp_service_principal.lz_tf_deploy.resource_id
  # This SP will be creating Service Principals for LZs, and 
  # org-level groups, so needs org-level admin
  role = "roles/admin"
}

# Uncomment in the future if org-level SPs support workload identity
# resource "hcp_iam_workload_identity_provider" "lz_tf_deploy_provider" {
#   name              = "lz-hcp-tf-deploy-provider"
#   service_principal = hcp_service_principal.lz_tf_deploy.resource_name
#   description       = "Allow this workspace on HCP TF to Manage HCP Packer buckets and channels"

#   oidc = {
#     issuer_uri = "https://app.terraform.io"
#   }

#   # Only allow workloads running from the correct HCP TF Project
#   conditional_access = join("", [
#     "jwt_claims.sub matches `^organization:${var.terraform_organization}",
#     ":project:${tfe_project.lz_admin.name}:workspace:.+:run_phase:.+`"
#   ])
# }

# Note this requires the Terraform to be run regularly
resource "time_rotating" "key_rotation" {
  rotation_days = 14
}

resource "hcp_service_principal_key" "key" {
  service_principal = hcp_service_principal.lz_tf_deploy.resource_name
  rotate_triggers = {
    rotation_time = time_rotating.key_rotation.rotation_rfc3339
  }
}

resource "tfe_variable_set" "lz_admin" {
  name              = "LZ Admin Variables"
  description       = "A set of variables for the lz-admin project"
  global            = false
  parent_project_id = tfe_project.lz_admin.id
}

resource "tfe_project_variable_set" "lz_admin" {
  project_id      = tfe_project.lz_admin.id
  variable_set_id = tfe_variable_set.lz_admin.id
}

# Credentials for HCP provider authentication
resource "tfe_variable" "lz_hcp_provider_client_id" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "HCP_CLIENT_ID"
  value           = hcp_service_principal_key.key.client_id
  category        = "env"
}

resource "tfe_variable" "lz_hcp_provider_client_secret" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "HCP_CLIENT_SECRET"
  value           = hcp_service_principal_key.key.client_secret
  category        = "env"
  sensitive       = true
}

resource "tfe_variable" "lz_hcp_project_id" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "HCP_PROJECT_ID"
  value           = hcp_project.admin.resource_id
  category        = "env"
}

resource "tfe_variable" "tfe_org" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "TFE_ORGANIZATION"
  value           = var.terraform_organization
  category        = "env"
  description     = "Terraform organization name"
}

resource "tfe_variable" "tfe_org_tf" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "terraform_organization"
  value           = var.terraform_organization
  category        = "terraform"
  description     = "Terraform organization name - Terraform variable for OIDC claims"
}

# LZ Admin Team only for generating a team token
resource "tfe_team" "lz_admin_team" {
  name       = "lz-admin"
  visibility = "organization"

  organization_access {
    manage_workspaces = true
    manage_projects   = true
    manage_policies   = true
    manage_teams      = true
    manage_membership = true
  }
}

resource "tfe_team_token" "lz_admin" {
  team_id     = tfe_team.lz_admin_team.id
  description = "Token used by the lz-admin project to manage other projects, teams etc."
}

resource "tfe_variable" "lz_admin_token" {
  variable_set_id = tfe_variable_set.lz_admin.id
  key             = "TFE_TOKEN"
  value           = tfe_team_token.lz_admin.token
  category        = "env"
  description     = "Token used for TFE provider in LZ Admin project"
  sensitive       = true
}

module "aws_oidc_lz" {
  source                 = "app.terraform.io/philbrook/tfe-oidc/aws"
  version                = "1.0.0"
  mode                   = "project"
  terraform_organization = var.terraform_organization
  tf_project_name        = tfe_project.lz_admin.name
  tf_project_id          = tfe_project.lz_admin.id
  aws_policy_arn         = aws_iam_policy.self_tf_policy.arn
}

# Variable set and variables for *the created landing zone projects* for HCP authentication
# There is a limit of 5 HCP Service Principals per HCP Project, so we are sharing a
# read-only HCP Service Principals as it is only used for sourcing HCP Packer artifact versions

resource "hcp_service_principal" "app_tf_read" {
  name   = "apps-tf-hcp-read"
  parent = hcp_project.admin.resource_name
}

# Scope this principal to only be able to read from the project
# Note that you can't go finer-grained than project level
# or the provider authentication will not work
resource "hcp_project_iam_binding" "app_tf_read" {
  principal_id = hcp_service_principal.app_tf_read.resource_id
  project_id   = hcp_project.admin.resource_id
  role         = "roles/viewer"
}

resource "hcp_iam_workload_identity_provider" "app_tf_read_provider" {
  name              = "apps-hcp-tf-read-provider"
  service_principal = hcp_service_principal.app_tf_read.resource_name
  description       = "Allow this project on HCP TF to read HCP Packer artifact versions"

  oidc = {
    issuer_uri        = "https://app.terraform.io"
    allowed_audiences = [local.hcp_audience]
  }

  # Allow workloads running from any project in the HCP TF Organization
  conditional_access = "jwt_claims.sub matches `^organization:${var.terraform_organization}:.+`"
}

resource "tfe_variable_set" "shared_app" {
  name   = "hcp-auth-shared-apps"
  global = false
}

# Required environment variable to enable HCP dynamic credentials
resource "tfe_variable" "app_hcp_provider_auth" {
  variable_set_id = tfe_variable_set.shared_app.id
  key             = "TFC_HCP_PROVIDER_AUTH"
  value           = "true"
  category        = "env"
  description     = "Enable HCP dynamic credentials authentication"
}

# Required environment variable for the workload identity provider resource name
resource "tfe_variable" "app_hcp_run_provider_resource_name" {
  variable_set_id = tfe_variable_set.shared_app.id
  key             = "TFC_HCP_RUN_PROVIDER_RESOURCE_NAME"
  value           = hcp_iam_workload_identity_provider.app_tf_read_provider.resource_name
  category        = "env"
  description     = "Resource name of the App workload identity provider for HCP authentication. "
}

resource "tfe_variable" "app_hcp_run_provider_audience" {
  variable_set_id = tfe_variable_set.shared_app.id
  key             = "TFC_HCP_WORKLOAD_IDENTITY_AUDIENCE"
  value           = local.hcp_audience
  category        = "env"
  description     = "Audience to use in the OIDC"
}
