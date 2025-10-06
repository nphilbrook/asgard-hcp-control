provider "tfe" {
  organization = var.terraform_organization
}

provider "hcp" {
}

provider "time" {
}

locals {
  tags_labels = { "created-by" = "terraform",
    "source-workspace-slug" = var.TFC_WORKSPACE_SLUG
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.tags_labels
  }
}
