terraform {
  required_version = "~>1.12"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.67"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~>0.107"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.13"
    }
  }
}
