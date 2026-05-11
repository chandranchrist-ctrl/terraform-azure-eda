# Admin → Full control
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.owner_group_id
}

# DevOps → Contributor (secrets, keys, etc.)
resource "azurerm_role_assignment" "kv_devops" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = var.devops_group_id
}

resource "azurerm_role_assignment" "kv_tf_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

