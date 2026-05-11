# Network - VNet Peering
output "vnet_peering_ids" {
  description = "IDs of the created VNet peerings"
  value       = { for k, v in azurerm_virtual_network_peering.vnet_peering : k => v.id }
}