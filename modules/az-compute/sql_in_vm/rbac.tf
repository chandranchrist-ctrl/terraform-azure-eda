# RBAC acccess to keyvault
/* 
resource "azurerm_role_assignment" "vm_kv_access" {
  for_each = azurerm_windows_virtual_machine.vm

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity[0].principal_id
} 
*/

# Key Vault Access Policy

/* Grants VM identity access to Key Vault secrets
Required to fetch credentials securely */

resource "azurerm_key_vault_access_policy" "vm" {
  for_each = azurerm_windows_virtual_machine.vm

  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}