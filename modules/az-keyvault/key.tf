/* Creates the encryption key used for SQL TDE */
resource "azurerm_key_vault_key" "sql_tde_key" {
  name         = var.tde_key_name
  key_vault_id = azurerm_key_vault.kv.id

  key_type = "RSA"
  key_size = 2048

  /* Defines the capabilities of the key itself, not permissions. */
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "verify",
    "wrapKey",
    "unwrapKey"
  ]

  depends_on = [
    azurerm_role_assignment.kv_tf_admin
  ]
}

resource "azurerm_key_vault_key" "acr_cmk" {
  name         = var.acr_key_name
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "verify",
    "wrapKey",
    "unwrapKey"
  ]

  depends_on = [
    azurerm_role_assignment.kv_tf_admin
  ]
}