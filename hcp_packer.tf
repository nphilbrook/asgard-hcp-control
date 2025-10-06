# Packer build bucket
resource "hcp_packer_bucket" "packer_build" {
  project_id = hcp_project.admin.resource_id
  name       = "packer-build"
}

resource "hcp_packer_channel" "production" {
  project_id  = hcp_project.admin.resource_id
  name        = "prod"
  bucket_name = hcp_packer_bucket.packer_build.name
}

resource "hcp_packer_channel" "dev" {
  project_id  = hcp_project.admin.resource_id
  name        = "dev"
  bucket_name = hcp_packer_bucket.packer_build.name
}

# base bucket and channels
resource "hcp_packer_bucket" "base" {
  project_id = hcp_project.admin.resource_id
  name       = "base"
}

resource "hcp_packer_channel" "base_production" {
  project_id  = hcp_project.admin.resource_id
  name        = "prod"
  bucket_name = hcp_packer_bucket.base.name
}

# TODO: when an ephemeral data source exists for this,
# use it instead. This will result in the HMAC
# key being written to state.
data "hcp_packer_run_task" "registry" {
  project_id = hcp_project.admin.resource_id
}

resource "tfe_organization_run_task" "packer" {
  url         = data.hcp_packer_run_task.registry.endpoint_url
  name        = "HCPPacker"
  enabled     = true
  description = "Verifies AMIs are not revoked in the HCP Packer Registry"
  hmac_key_wo = data.hcp_packer_run_task.registry.hmac_key
}

resource "tfe_organization_run_task_global_settings" "packer" {
  task_id           = tfe_organization_run_task.packer.id
  enabled           = true
  enforcement_level = "mandatory"
  stages            = ["post_plan"]
}
