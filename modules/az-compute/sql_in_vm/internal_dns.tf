resource "azurerm_private_dns_a_record" "vm" {

  for_each = azurerm_windows_virtual_machine.vm

  name                = each.key
  zone_name           = var.internal_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300

  records = [
    azurerm_network_interface.nic[each.key].private_ip_address
  ]
}