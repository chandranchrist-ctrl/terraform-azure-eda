resource "azurerm_logic_app_workflow" "logic_app" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name

  enabled = true

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  parameters = {
    "$connections" = jsonencode({
      gmail = {
        connectionId   = var.gmail_api_connection_id
        connectionName = var.gmail_api_connection_name

        id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/gmail"
      }
    })
  }

  tags = var.tags
}