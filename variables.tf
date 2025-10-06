variable "github_organization" {
  description = "Existing GitHub organization name (for linking to VCS)"
  type        = string
}

variable "terraform_organization" {
  description = "Existing HCP Terraform organization name"
  type        = string
}

variable "terraform_project_name" {
  description = "HCP Terraform project to create"
  type        = string
}

variable "hcp_project_name" {
  description = "HCP project to create"
  type        = string
}

# Automatically injected by Terraform
variable "TFC_WORKSPACE_SLUG" {
  type = string
}
