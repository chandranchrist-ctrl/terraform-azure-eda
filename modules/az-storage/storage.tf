# Storage - Network Rules
resource "azurerm_storage_account_network_rules" "storage_network_rules" {
  storage_account_id = azurerm_storage_account.storage_account.id

  default_action = "Deny"
  bypass = [
    "AzureServices"
  ]

  virtual_network_subnet_ids = var.allowed_subnet_ids
  ip_rules                   = var.allowed_ip_rules
}

# Storage - Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.replication_type


  identity {
    type = "SystemAssigned"
  }

  dns_endpoint_type             = var.dns_endpoint_type
  public_network_access_enabled = var.public_network_access

  shared_access_key_enabled = true

  allow_nested_items_to_be_public = false

  # Blob Properties (versioning + retention)
  blob_properties {

    versioning_enabled = var.blob_versioning_enabled

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  tags = var.tags
}