# Network - Subnet Mapping
locals {
  subnet_map = merge([
    for vnet_key, subnets in var.subnet_address_space : {
      for subnet_key, subnet in subnets :
      "${vnet_key}-${subnet_key}" => {
        vnet_key   = vnet_key
        subnet_key = subnet_key
        cidr       = subnet.cidr
        tags       = try(subnet.tags, {})
        delegation = try(subnet.delegation, null)
      }
    }
  ]...)
}

# Network - Subnet
resource "azurerm_subnet" "subnet" {
  for_each = local.subnet_map

  name = (
    can(regex("subnet$", lower(each.value.subnet_key)))
    ? each.value.subnet_key
    : "${var.env}-${each.value.vnet_key}-${each.value.subnet_key}-subnet"
  )

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  default_outbound_access_enabled = var.default_outbound_access_enabled

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage",
    "Microsoft.Sql"
  ]

  /* Conditionally creates a subnet delegation block when delegation is provided; 
dynamically assigns the delegation name and service details (service name and allowed actions) to enable Azure service integration (e.g., App Service) with the subnet. */
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []

    content {
      name = each.value.delegation.name

      service_delegation {
        name    = each.value.delegation.service_delegation.name
        actions = each.value.delegation.service_delegation.actions
      }
    }
  }
}