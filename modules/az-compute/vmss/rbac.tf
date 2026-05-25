resource "azurerm_key_vault_access_policy" "vmss" {
  key_vault_id = var.key_vault_id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_windows_virtual_machine_scale_set.vmss.identity[0].principal_id

  secret_permissions = ["Get", "List"]

  certificate_permissions = ["Get", "List"]
}


resource "azurerm_role_assignment" "vmss_kv_secret_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_windows_virtual_machine_scale_set.vmss.identity[0].principal_id
}

resource "azurerm_role_assignment" "vmss_queue_access" {
  scope                = data.azurerm_storage_account.queue.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_windows_virtual_machine_scale_set.vmss.identity[0].principal_id
}