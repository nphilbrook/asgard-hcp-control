# TO BE UNCOMMENTED if org-level SPs ever support workload identity federation,
# or project-level SPs can be granted org-level roles.

resource "hcp_service_principal" "tf_deploy" {
  name   = "hcp-tf-deploy"
  parent = hcp_project.admin.resource_name
}

# Obviated by below
# resource "hcp_project_iam_binding" "tf_deploy_admin" {
#   principal_id = hcp_service_principal.tf_deploy.resource_id
#   project_id   = hcp_project.admin.resource_id
#   role         = "roles/admin"
# }

# Does it work?
resource "hcp_organization_iam_binding" "tf_deploy_admin_org" {
  principal_id = hcp_service_principal.tf_deploy.resource_id
  role         = "roles/admin"
}


resource "hcp_iam_workload_identity_provider" "tf_deploy_provider" {
  name              = "hcp-tf-deploy-provider"
  service_principal = hcp_service_principal.tf_deploy.resource_name
  description       = "Allow this workspace on HCP TF to manage HCP"

  oidc = {
    issuer_uri = "https://app.terraform.io"
  }

  # Only allow workloads running from the correct HCP TF workspace
  conditional_access = join("", [
    "jwt_claims.sub matches `^organization:${var.terraform_organization}",
    ":project:${tfe_project.self.name}:workspace:${tfe_workspace.self.name}:run_phase:.+`"
  ])
}
# END TO BE UNCOMMENTED

# Projects
resource "hcp_project" "admin" {
  name        = var.hcp_project_name
  description = "Project for non-Waypoint HCP resources (Packer)"
}

resource "hcp_project" "waypoint" {
  name        = "${var.hcp_project_name}-waypoint"
  description = "${var.hcp_project_name} Waypoint project for fine-grained access control of Waypoint applications."
}

# Groups
resource "hcp_group" "engineering" {
  display_name = "engineering"
  description  = "Group for all engineers in the organization."
}

resource "hcp_project_iam_binding" "engineering_viewer" {
  project_id   = hcp_project.admin.resource_id
  principal_id = hcp_group.engineering.resource_id
  role         = "roles/viewer"
}

resource "hcp_project_iam_binding" "engineering_waypoint_contributor" {
  project_id   = hcp_project.waypoint.resource_id
  principal_id = hcp_group.engineering.resource_id
  role         = "roles/contributor"
}

resource "hcp_group" "admins" {
  display_name = "admins"
  description  = "Group for all administrators in the organization."
}

resource "hcp_project_iam_binding" "admins_admin" {
  project_id   = hcp_project.admin.resource_id
  principal_id = hcp_group.admins.resource_id
  role         = "roles/admin"
}

resource "hcp_project_iam_binding" "admins_admin_waypoint" {
  project_id   = hcp_project.waypoint.resource_id
  principal_id = hcp_group.admins.resource_id
  role         = "roles/admin"
}
