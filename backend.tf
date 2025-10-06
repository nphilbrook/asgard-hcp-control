terraform {
  cloud {
    organization = "philbrook"
    workspaces {
      name = "asgard-hcp-control"
    }
  }
}
