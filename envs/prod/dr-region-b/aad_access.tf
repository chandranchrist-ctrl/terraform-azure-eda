# Get current user (bootstrap)
data "azuread_client_config" "current" {}

# Common members (avoid duplication)
locals {
  admin_members = [
    data.azuread_client_config.current.object_id
  ]

  devops_members = []
}

# Centralized AD groups
module "access" {
  source = "../../../modules/az-ad-access"

  groups = {
    # Key Vault
    kv_admins = {
      name    = "kv-admins"
      members = local.admin_members
    }

    kv_devops = {
      name    = "kv-devops"
      members = local.devops_members
    }

    # law_admins = {
    #   name    = "law-admins"
    #   members = local.admin_members
    # }

    # law_devops = {
    #   name    = "law-devops"
    #   members = local.devops_members
    # }
  }
}