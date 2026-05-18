/* Creates an App Service Plan that defines the compute resources (CPU, memory, scaling, OS, and pricing tier) for hosting App Services */
resource "azurerm_service_plan" "appserviceplan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = var.os_type
  sku_name = var.sku_name

  zone_balancing_enabled = var.zone_balancing_enabled
}