# Storage - Queues
resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name               = each.value
  storage_account_id = azurerm_storage_account.storage_account.id
}

# Storage Queue Properties
resource "azurerm_storage_account_queue_properties" "queue_properties" {
  count = length(var.queues) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.storage_account.id

  logging {
    delete                = var.queue_logging_delete
    read                  = var.queue_logging_read
    write                 = var.queue_logging_write
    version               = var.queue_logging_version
    retention_policy_days = 7
  }

  hour_metrics {
    version               = "1.0"
    include_apis          = true
    retention_policy_days = 7
  }

  minute_metrics {
    version               = "1.0"
    include_apis          = true
    retention_policy_days = 7
  }
}