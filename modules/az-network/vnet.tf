# Network - Virtual Network
resource "azurerm_virtual_network" "vnet" {
  for_each = var.vnet_address_space

  name                = "${var.env}-${var.workload}-${each.key}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = each.value
  tags                = var.tags
}