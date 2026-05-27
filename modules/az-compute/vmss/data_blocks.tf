# Fetches details of currently authenticated Azure client/service principal
data "azurerm_client_config" "current" {}

# Retrieves local administrator credentials stored securely in Key Vault
data "azurerm_key_vault_secret" "localadmin_credentials" {
  name         = var.localadmin_credentials_secret_name
  key_vault_id = var.key_vault_id
}

# Decodes Key Vault secret JSON into username/password object
locals {
  localadmin_creds = jsondecode(data.azurerm_key_vault_secret.localadmin_credentials.value)
}

# Fetches existing storage account details for VM boot diagnostics
data "azurerm_storage_account" "diag" {
  count = var.boot_diagnostics_mode == "existing" ? 1 : 0

  name                = var.boot_diagnostics_storage_account_name
  resource_group_name = var.resource_group_name
}

# Retrieves existing load balancer details when using pre-created LBs
data "azurerm_lb" "existing" {

  for_each = var.enable_lb ? {
    for lb in var.load_balancers :
    lb.lb_name => lb
  } : {}

  name                = each.value.lb_name
  resource_group_name = var.resource_group_name
}

# Fetches backend address pool IDs from existing load balancers
data "azurerm_lb_backend_address_pool" "existing" {

  for_each = var.enable_lb ? {
    for lb in var.load_balancers :
    lb.lb_name => lb
  } : {}

  name            = each.value.lb_backend_pool_name
  loadbalancer_id = data.azurerm_lb.existing[each.key].id
}

locals {

  # Stores backend pool IDs collected from existing load balancers
  existing_lb_backend_pool_ids = [

    for pool in data.azurerm_lb_backend_address_pool.existing :
    pool.id

  ]

  # Combines new and existing LB backend pool IDs while removing duplicates
  lb_backend_pool_ids = distinct(concat(
    var.lb_backend_pool_ids,
    local.existing_lb_backend_pool_ids
  ))
}

# Retrieves queue storage account details for application queue integration
data "azurerm_storage_account" "queue" {
  name                = var.queue_storage_account_name
  resource_group_name = var.resource_group_name
}
