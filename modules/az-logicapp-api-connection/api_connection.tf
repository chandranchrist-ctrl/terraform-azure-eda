# Creates Gmail API connection for Logic App email integration
resource "azurerm_api_connection" "gmail" {
  name                = var.api_connection_name
  resource_group_name = var.resource_group_name

  # Here we are using the built-in Gmail connector provided by Azure Logic Apps
  managed_api_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/gmail"

  display_name = "gmail-connection"
}