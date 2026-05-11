/* Access Policy grants Key Vault access to the current Terraform execution identity. */
resource "azurerm_key_vault_access_policy" "me" {
  count = var.create_access_policy_me ? 1 : 0

  key_vault_id = azurerm_key_vault.kv.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Import",
    "Delete"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Import",
    "Update",
    "Backup",
    "Restore",
    "Recover",
    "Purge",
    "Encrypt",
    "Decrypt",
    "Sign",
    "Verify",
    "WrapKey",
    "UnwrapKey",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}