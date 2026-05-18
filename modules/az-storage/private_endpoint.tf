resource "azurerm_private_endpoint" "storage_blob" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.private_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.storage_account.id

    subresource_names = ["blob"]

    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "blob-dns-zone-group"

    private_dns_zone_ids = [
      var.blob_private_dns_zone_id
    ]
  }
}

resource "azurerm_private_endpoint" "storage_queue" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.storage_account_name}-queue-pe"
  location            = var.location
  resource_group_name = var.resource_group_name

  subnet_id = var.private_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-queue-psc"
    private_connection_resource_id = azurerm_storage_account.storage_account.id

    subresource_names = ["queue"]

    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "queue-dns-zone-group"

    private_dns_zone_ids = [
      var.queue_private_dns_zone_id
    ]
  }
}