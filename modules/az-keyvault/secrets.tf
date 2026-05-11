# Security - Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.kv_tf_admin
  ]
}

# Security - SSH Public Key
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.ssh_secret_name
  value        = var.ssh_public_key
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.kv_tf_admin
  ]
}