# Workspace for deploying an EKS cluster for HCP Terraform agents
# resource "tfe_workspace" "eks_agents" {
#   name              = "aws-eks-agents"
#   project_id        = tfe_project.self.id
#   terraform_version = "1.12.2"
#   vcs_repo {
#     github_app_installation_id = data.tfe_github_app_installation.gha_installation.id
#     identifier                 = "${var.github_organization}/aws-eks-agents"
#   }
# }

# module "aws_oidc_eks" {
#   source                 = "app.terraform.io/philbrook/tfe-oidc/aws"
#   version                = "1.0.0"
#   mode                   = "workspace"
#   terraform_organization = var.terraform_organization
#   tf_workspace_name      = tfe_workspace.eks_agents.name
#   tf_workspace_id        = tfe_workspace.eks_agents.id
#   aws_policy_arn         = aws_iam_policy.eks_management_policy.arn
# }
