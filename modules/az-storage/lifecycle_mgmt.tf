# Storage - Lifecycle Management

/* Lifecycle management automatically deletes/archives blobs based on rules
dynamic "rule" allows creating multiple lifecycle rules from input (var.lifecycle_rules)
empty list = no rules created, list provided = rules applied to matching blobs */

resource "azurerm_storage_management_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.storage_account.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      name    = rule.value.name
      enabled = true

      filters {
        blob_types   = ["blockBlob"]
        prefix_match = rule.value.prefix
      }

      actions {
        base_blob {
          delete_after_days_since_modification_greater_than = rule.value.days
        }
      }
    }
  }
}