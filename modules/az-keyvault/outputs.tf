output "key_vault_id" {
  value       = azurerm_key_vault.kv.id
  description = "Key Vault ID"
}

output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault Name"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI"
}

output "certificate_secret_ids" {
  value = {
    for cert in azurerm_key_vault_certificate.cert :
    cert.name => cert.secret_id
  }
  description = "Map of all certificate names to secret IDs"
}

output "sql_tde_key_id" {
  value       = azurerm_key_vault_key.sql_tde_key.id
  description = "SQL TDE Key ID"
}

output "acr_cmk_id" {
  value       = azurerm_key_vault_key.acr_cmk.id
  description = "ACR CMK Key ID"
}