Bootstrap and continue to configure HCP and HCP Terraform

Steps to use
1. Create a workspace via the HCP Terraform UI
    1. Link to this repository (create a new Github App connection if needed)
    1. Define the requried variables (the UI should prompt you):
        * github_organization
        * terraform_organization
        * terraform_project_name
        * hcp_project_name
1. Fill in the workspace ID for your new workspace in the import.tf file
1. Create an HCP Service Princpal in your HCP Organization
    1. Grant the Service Principal the Admin role
    1. Generate keys for this principal and set the `HCP_CLIENT_ID` and `HCP_CLIENT_SECRET`
       environment variable on the new workspace (this is temporary)
1. Generate an API Token for either your HCP Terraform user, or ideally a service account user managed in your Identity Provider.
Set this token as a `TFE_TOKEN` environment variable on the workspace. *The user associated with this token must create the Github App integration as an organizational bootstrap requirement to manage workspace VCS connections via the TFE provider in this repo.*
1. Provide temporary AWS credentials to your workspace. These can be in the form of an Access Key / Secret Key, or a federated OIDC role. This workspace will create a new role with OIDC federation and attach it to the workspace for future runs, so the temporary credentials can be removed at that time (refenence self.tf and aws_policies.tf).
1. Apply the code

NOTE: At this time Org-level HCP Service Principals do not support [workload identity](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/hcp-configuration) federation, so leave the `HCP_*` environment variables in place. If there is a time when this is supported, the commented code in hcp.tf can be used for
workload identity deferation and the `HCP_*` environment variables can be removed and the key deleted.
