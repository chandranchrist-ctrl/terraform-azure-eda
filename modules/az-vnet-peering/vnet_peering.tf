# Network - VNet Peering
resource "azurerm_virtual_network_peering" "vnet_peering" {
  for_each = var.peerings

  name                         = each.value.name
  resource_group_name          = each.value.resource_group
  virtual_network_name         = each.value.vnet_name
  remote_virtual_network_id    = each.value.remote_vnet_id
  allow_virtual_network_access = each.value.allow_vnet_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}