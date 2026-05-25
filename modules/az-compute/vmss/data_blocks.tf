data "azurerm_client_config" "current" {}

data "azurerm_key_vault_secret" "localadmin_credentials" {
  name         = var.localadmin_credentials_secret_name
  key_vault_id = var.key_vault_id
}

locals {
  localadmin_creds = jsondecode(data.azurerm_key_vault_secret.localadmin_credentials.value)
}

data "azurerm_storage_account" "diag" {
  count = var.boot_diagnostics_mode == "existing" ? 1 : 0

  name                = var.boot_diagnostics_storage_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_lb" "existing" {

  for_each = var.enable_lb ? {
    for lb in var.load_balancers :
    lb.lb_name => lb
  } : {}

  name                = each.value.lb_name
  resource_group_name = var.resource_group_name
}

data "azurerm_lb_backend_address_pool" "existing" {

  for_each = var.enable_lb ? {
    for lb in var.load_balancers :
    lb.lb_name => lb
  } : {}

  name            = each.value.lb_backend_pool_name
  loadbalancer_id = data.azurerm_lb.existing[each.key].id
}

locals {

  existing_lb_backend_pool_ids = [

    for pool in data.azurerm_lb_backend_address_pool.existing :
    pool.id

  ]

  lb_backend_pool_ids = distinct(concat(
    var.lb_backend_pool_ids,
    local.existing_lb_backend_pool_ids
  ))
}

data "azurerm_storage_account" "queue" {
  name                = var.queue_storage_account_name
  resource_group_name = var.resource_group_name
}

# data "azurerm_lb" "existing" {
#   count = var.enable_lb && var.lb_backend_pool_id == null && var.lb_name != null ? 1 : 0

#   name                = var.lb_name
#   resource_group_name = var.resource_group_name
# }

# data "azurerm_lb_backend_address_pool" "existing" {
#   count = var.enable_lb && var.lb_backend_pool_id == null && var.lb_backend_pool_name != null ? 1 : 0

#   name            = var.lb_backend_pool_name
#   loadbalancer_id = data.azurerm_lb.existing[0].id
# }

# locals {
#   lb_backend_pool_id = (
#     var.lb_backend_pool_id != null
#     ? var.lb_backend_pool_id
#     : try(data.azurerm_lb_backend_address_pool.existing[0].id, null)
#   )
# }
