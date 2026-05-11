/* Imports certificates (PFX) into Key Vault;
for_each = creates one certificate per item in var.certificates;
Use when certificates are already generated and need to be stored securely in Key Vault */

# Security - Certificates
resource "azurerm_key_vault_certificate" "cert" {
  for_each = { for c in var.certificates : c.name => c }

  name         = each.value.name
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64(each.value.pfx_path)
    password = each.value.password
  }

  depends_on = [
    azurerm_role_assignment.kv_tf_admin
  ]
}