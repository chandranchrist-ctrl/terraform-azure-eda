data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "diag" {
  count = local.use_existing_sa ? 1 : 0

  name                = var.boot_diagnostics_storage_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "localadmin_credentials" {
  name         = var.localadmin_credentials_secret_name
  key_vault_id = var.key_vault_id
}


locals {
  localadmin_creds = jsondecode(data.azurerm_key_vault_secret.localadmin_credentials.value)
}

# Data for backup & recovery serivce vault
data "azurerm_recovery_services_vault" "vault" {
  count = var.enable_backup ? 1 : 0

  name                = var.recovery_services_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_backup_policy_vm" "policy" {
  count = var.enable_backup ? 1 : 0

  name                = var.backup_policy_vm
  recovery_vault_name = data.azurerm_recovery_services_vault.vault[0].name
  resource_group_name = data.azurerm_recovery_services_vault.vault[0].resource_group_name
}


data "azurerm_lb" "existing" {
  count = var.enable_lb && var.lb_backend_pool_id == null && var.lb_name != null ? 1 : 0

  name                = var.lb_name
  resource_group_name = var.resource_group_name
}

data "azurerm_lb_backend_address_pool" "existing" {
  count = var.enable_lb && var.lb_backend_pool_id == null && var.lb_backend_pool_name != null ? 1 : 0

  name            = var.lb_backend_pool_name
  loadbalancer_id = data.azurerm_lb.existing[0].id
}

locals {
  lb_enabled = var.enable_lb

  resolved_lb_backend_pool_id = (
    var.lb_backend_pool_id != null
    ? var.lb_backend_pool_id
    : (
      length(data.azurerm_lb_backend_address_pool.existing) > 0
      ? data.azurerm_lb_backend_address_pool.existing[0].id
      : null
    )
  )
}

