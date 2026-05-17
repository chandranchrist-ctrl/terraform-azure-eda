# Key Vault Secret Data Source
data "azurerm_key_vault_secret" "godaddy" {

  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

# Decode GoDaddy credentials from Key Vault secret
locals {

  godaddy_credentials = jsondecode(
    data.azurerm_key_vault_secret.godaddy.value
  )

  godaddy_api_key = local.godaddy_credentials.Key

  godaddy_api_secret = local.godaddy_credentials.Secret
}

# Key Vault Access Policy for Static Web App's Managed Identity
resource "azurerm_role_assignment" "kv_secrets_user" {

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_static_web_app.static_web_app.identity[0].principal_id
}
