# Key Vault Secret
data "azurerm_key_vault_secret" "godaddy" {

  count = var.enable_external_dns && var.frontend_ip_type == "Public" ? 1 : 0

  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

# Decode GoDaddy Credentials
locals {

  godaddy_credentials = (
    var.enable_external_dns && var.frontend_ip_type == "Public"
    ) ? jsondecode(
    data.azurerm_key_vault_secret.godaddy[0].value
  ) : {}

  godaddy_api_key = (
    var.enable_external_dns && var.frontend_ip_type == "Public"
  ) ? local.godaddy_credentials.Key : null

  godaddy_api_secret = (
    var.enable_external_dns && var.frontend_ip_type == "Public"
  ) ? local.godaddy_credentials.Secret : null
}