# Retrieves and decodes GoDaddy API credentials from Key Vault for automated DNS record management
# Key Vault Secret Data Source
data "azurerm_key_vault_secret" "godaddy" {

  count = var.create_dns_record ? 1 : 0

  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

locals {

  # Decodes GoDaddy API credentials stored as JSON secret
  godaddy_credentials = var.create_dns_record ? jsondecode(
    data.azurerm_key_vault_secret.godaddy[0].value
  ) : null

  godaddy_api_key = var.create_dns_record ? local.godaddy_credentials.Key : null

  godaddy_api_secret = var.create_dns_record ? local.godaddy_credentials.Secret : null
}