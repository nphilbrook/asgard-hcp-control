# Extra WIP for TFE to grab the autoscaling app's image
resource "hcp_iam_workload_identity_provider" "tfe_tf_read_provider" {
  name              = "tfe-hcp-tf-read-provider"
  service_principal = hcp_service_principal.app_tf_read.resource_name
  description       = "Allow this workspace on TFE to read HCP Packer artifact versions"

  oidc = {
    issuer_uri        = "https://tfe-pi-new.nick-philbrook.sbx.hashidemos.io"
    allowed_audiences = [local.hcp_audience]
  }

  # Allow workloads running from any project in the HCP TF Organization
  conditional_access = "jwt_claims.sub matches `^organization:philbrook-tfe:.+`"
}

# Required environment variable to enable HCP dynamic credentials
output "app_hcp_provider_auth" {
  value       = "TFC_HCP_PROVIDER_AUTH=true"
  description = "Enable HCP dynamic credentials authentication"
}

# Required environment variable for the workload identity provider resource name
output "app_hcp_run_provider_resource_name" {
  value       = "TFC_HCP_RUN_PROVIDER_RESOURCE_NAME=${hcp_iam_workload_identity_provider.tfe_tf_read_provider.resource_name}"
  description = "Resource name of the App workload identity provider for HCP authentication. "
}

output "app_hcp_run_provider_audience" {
  value       = "TFC_HCP_WORKLOAD_IDENTITY_AUDIENCE=${local.hcp_audience}"
  description = "Audience to use in the OIDC"
}
