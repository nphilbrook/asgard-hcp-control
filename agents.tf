# Agent pool created and managed by the HCP Terraform Operator
# reference 'aws-eks-agents' repository
# data "tfe_agent_pool" "asgard_agents" {
#   name = "asgard-agent-pool"
# }

# resource "tfe_organization_default_settings" "org_default_agents" {
#   default_execution_mode = "agent"
#   default_agent_pool_id  = data.tfe_agent_pool.asgard_agents.id
# }
