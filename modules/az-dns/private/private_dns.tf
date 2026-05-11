# Create Private DNS Zones
resource "azurerm_private_dns_zone" "zones" {
  for_each = toset(var.zones)

  name                = each.value
  resource_group_name = var.resource_group_name
}


# Zone to VNet Mapping
locals {
  zone_vnet_links = flatten([
    for zone in var.zones : [
      for idx, vnet_id in var.vnet_ids : {
        key     = "${replace(zone, ".", "-")}-vnet-${idx}" # static key
        zone    = zone
        vnet_id = vnet_id
      }
    ]
  ])
}

# DNS Zone to VNet Link
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = {
    for item in local.zone_vnet_links :
    item.key => item
  }

  name = each.key

  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.zone
  virtual_network_id    = each.value.vnet_id

  /* false = no auto DNS record registration, true = enables auto registration */

  registration_enabled = false

  /*  false = recommended for production (manual control of DNS records, avoids conflicts);
  true = auto-registers VM DNS records (use only for simple VM-based setups) */
  depends_on = [azurerm_private_dns_zone.zones]
}