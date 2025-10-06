# Creates a policy that will be used to define the permissions that
# *this* workspace has within AWS, and additionally the LZ project
#
# The Action and Resource blocks in this code are scoped to IAM management,
# adhering to the principle of least privilege for managing IAM roles,
# policies, and role/policy bindings. As this workspace and the LZ project will not
# be creating much in AWS other than IAM policies for other workspaces
data "aws_iam_policy_document" "iam_management_policy" {
  statement {
    effect = "Allow"
    actions = [
      # Required to lookup the OIDC provider
      "iam:ListOpenIDConnectProviders",
      "iam:GetOpenIDConnectProvider"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:DeleteRole",
      "iam:ListRoles",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListInstanceProfilesForRole"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "self_tf_policy" {
  name        = "${var.terraform_project_name}-tf-control-repo"
  description = "TFC run policy for IAM management"
  policy      = data.aws_iam_policy_document.iam_management_policy.json
}

# Policy for aws-packer-compute stack

# Start with this
data "aws_iam_policy" "ec2_full" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Allow limited management of IAM for instance profile
data "aws_iam_policy_document" "packer_iam" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/${var.terraform_project_name}-packer-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["arn:aws:iam::*:policy/${var.terraform_project_name}-packer-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile"
    ]
    resources = ["arn:aws:iam::*:instance-profile/${var.terraform_project_name}-packer-*"]
  }

  statement {
    effect = "Allow"
    actions = [
      # KMS permissions for creating instances encrypted EBS volumes
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:ListKeys"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "packer_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.packer_iam.json,
    data.aws_iam_policy.ec2_full.policy
  ]
}

resource "aws_iam_policy" "packer_tf_policy" {
  name        = "${var.terraform_project_name}-tf-packer-policy"
  description = "TFC run policy for Packer instance profile management"
  policy      = data.aws_iam_policy_document.packer_combined.json
}

# Policy for aws-agents-eks workspace - comprehensive EKS management
data "aws_iam_policy_document" "eks_management_policy" {
  # EKS Cluster permissions
  statement {
    effect = "Allow"
    actions = [
      "eks:*"
    ]
    resources = ["*"]
  }

  # IAM management for EKS
  statement {
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:CreateRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:DeleteRole",
      "iam:ListRoles",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:GetInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:CreateOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider"
    ]
    resources = ["*"]
  }

  # EC2 Launch Template permissions
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:ModifyLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions"
    ]
    resources = ["*"]
  }

  # Security Group permissions
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupRules",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]
  }

  # VPC and networking permissions (read-only for existing resources)
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeRouteTables",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways"
    ]
    resources = ["*"]
  }

  # AMI permissions for launch templates
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings"
    ]
    resources = ["*"]
  }

  # STS permissions for session context
  statement {
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  # Additional permissions for EKS cluster operations
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots"
    ]
    resources = ["*"]
  }

  # KMS permissions for creating instances encrypted EBS volumes
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:ListKeys"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "eks_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.packer_iam.json,
    data.aws_iam_policy_document.eks_management_policy.json,
    data.aws_iam_policy.ec2_full.policy
  ]
}

resource "aws_iam_policy" "eks_management_policy" {
  name        = "eks-management"
  description = "policy for comprehensive EKS cluster and node group management"
  policy      = data.aws_iam_policy_document.eks_combined.json
}
