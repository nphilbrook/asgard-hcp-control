# This is the SP to actually build images in AWS
resource "hcp_service_principal" "packer" {
  name   = "packer"
  parent = hcp_project.admin.resource_name
}

resource "hcp_project_iam_binding" "packer_contrib" {
  principal_id = hcp_service_principal.packer.resource_id
  project_id   = hcp_project.admin.resource_id
  role         = "roles/contributor"
}

locals {
  # TODO : VERIFY THIS
  packer_instance_profile_role_arn = "arn:aws:iam::${data.aws_caller_identity.default.account_id}:role/${var.terraform_project_name}-packer"
  role_data                        = provider::aws::arn_parse(local.packer_instance_profile_role_arn)
  assume_role_arn = provider::aws::arn_build(local.role_data.partition,
    "sts",
    "",
    local.role_data.account_id,
    "assumed-role/${split("/", local.role_data.resource)[1]}"
  )
}

resource "hcp_iam_workload_identity_provider" "packer_provider" {
  name              = "packer"
  service_principal = hcp_service_principal.packer.resource_name
  description       = "Allow AWS IAM roles to assume this SP"

  aws = {
    account_id = local.role_data.account_id
  }

  # Only allow workloads running from the correct IAM Role
  conditional_access = "aws.arn matches `^${local.assume_role_arn}`"
}
