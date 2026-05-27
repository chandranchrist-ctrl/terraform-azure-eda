# Assigns RBAC permissions to Function App managed identity for Key Vault, Blob Storage, and Queue access required for EDA runtime processing
resource "azurerm_role_assignment" "functionapp_keyvault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_windows_function_app.function_app.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_blob_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"

  principal_id = azurerm_windows_function_app.function_app.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_queue_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"

  principal_id = azurerm_windows_function_app.function_app.identity[0].principal_id
}