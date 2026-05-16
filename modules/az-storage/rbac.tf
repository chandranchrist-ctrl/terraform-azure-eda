data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "tf_blob_writer" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}