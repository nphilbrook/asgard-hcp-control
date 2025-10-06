resource "tfe_project" "self" {
  name = var.terraform_project_name
}

resource "tfe_workspace" "self" {
  name              = "asgard-hcp-control"
  project_id        = tfe_project.self.id
  terraform_version = "1.13.3"
  vcs_repo {
    github_app_installation_id = data.tfe_github_app_installation.gha_installation.id
    identifier                 = "${var.github_organization}/asgard-hcp-control"
  }
}

# Reference comment at top of hcp.tf
# Required environment variable to enable HCP dynamic credentials
# resource "tfe_variable" "hcp_provider_auth" {
#   key          = "TFC_HCP_PROVIDER_AUTH"
#   value        = "true"
#   category     = "env"
#   workspace_id = tfe_workspace.self.id
#   description  = "Enable HCP dynamic credentials authentication"
# }

# Required environment variable for the workload identity provider resource name
# resource "tfe_variable" "hcp_run_provider_resource_name" {
#   key          = "TFC_HCP_RUN_PROVIDER_RESOURCE_NAME"
#   value        = hcp_iam_workload_identity_provider.tf_deploy_provider.resource_name
#   category     = "env"
#   workspace_id = tfe_workspace.self.id
#   description  = "Resource name of the workload identity provider for HCP authentication"
# }

module "aws_oidc" {
  source  = "app.terraform.io/philbrook/tfe-oidc/aws"
  version = "0.2.0"
  # source = "../../terraform-aws-tfe-oidc"
  mode                   = "workspace"
  terraform_organization = var.terraform_organization
  tf_workspace_name      = tfe_workspace.self.name
  tf_workspace_id        = tfe_workspace.self.id
  aws_policy_arn         = aws_iam_policy.self_tf_policy.arn
}

# Workaround for https://github.com/hashicorp/terraform-provider-hcp/issues/1360
resource "tfe_variable" "hcp_project_id" {
  key          = "HCP_PROJECT_ID"
  value        = hcp_project.waypoint.resource_id
  category     = "env"
  workspace_id = tfe_workspace.self.id
  description  = "HCP Project ID"
}
