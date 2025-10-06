resource "tfe_team" "waypoint" {
  name = "waypoint"
}

resource "tfe_team_project_access" "waypoint_lz_admin" {
  access     = "admin"
  team_id    = tfe_team.waypoint.id
  project_id = tfe_project.lz_admin.id
}

resource "tfe_team_token" "waypoint" {
  team_id     = tfe_team.waypoint.id
  description = "Token for Waypoint to access the HCP Terraform API"
}

resource "hcp_waypoint_tfc_config" "waypoint_config" {
  project_id   = hcp_project.waypoint.resource_id
  token        = tfe_team_token.waypoint.token
  tfc_org_name = var.terraform_organization
}

data "tfe_registry_module" "landing_zone" {
  organization    = var.terraform_organization
  name            = "tfe-app-lz"
  module_provider = "hcp"
}

resource "hcp_waypoint_template" "landing_zone" {
  name                            = "hcp-tfe-app-lz"
  summary                         = "Deploy an HCP/Terraform landing zone."
  description                     = "This template deploys an HCP Terraform project with AWS and HCP credentials and an HCP Packer bucket with standard channels."
  project_id                      = hcp_project.waypoint.resource_id
  terraform_project_id            = tfe_project.lz_admin.id
  terraform_no_code_module_source = data.tfe_registry_module.landing_zone.no_code_module_source
  terraform_no_code_module_id     = data.tfe_registry_module.landing_zone.no_code_module_id

  depends_on = [
    hcp_waypoint_tfc_config.waypoint_config
  ]
}

data "tfe_registry_module" "ephemeral_workspace" {
  organization    = var.terraform_organization
  name            = "ephemeral-workspace"
  module_provider = "tfe"
}

resource "hcp_waypoint_add_on_definition" "ephemeral_workspace_addon" {
  name                 = "ephemeral-workspace"
  summary              = "An add-on that provisions an ephemeral workspace."
  description          = <<EOF
This add-on provisions an ephemeral workspace in HCP Terraform. The workspace is provisioned
in the same HCP Terraform Project as the Application to which the add-on is added. The user
can choose the duration of inactivity which will trigger a destroy plan.
EOF
  project_id           = hcp_project.waypoint.resource_id
  terraform_project_id = tfe_project.lz_admin.id

  terraform_no_code_module_source = data.tfe_registry_module.ephemeral_workspace.no_code_module_source
  terraform_no_code_module_id     = data.tfe_registry_module.ephemeral_workspace.no_code_module_id
  variable_options = [
    {
      name          = "auto_destroy_activity_duration"
      user_editable = true
      variable_type = "string"
    },
  ]

  lifecycle {
    ignore_changes = [
      # Ignore a permadiff bug
      terraform_cloud_workspace_details
    ]
  }

  depends_on = [
    hcp_waypoint_tfc_config.waypoint_config
  ]
}
