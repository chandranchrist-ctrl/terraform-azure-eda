# VNets
output "vnets" {
  value = {
    for k, v in azurerm_virtual_network.vnet :
    k => {
      id   = v.id
      name = v.name
      cidr = v.address_space
    }
  }
}

# Network - Subnet
output "subnets" {
  value = {
    for k, v in azurerm_subnet.subnet :
    k => {
      id   = v.id
      name = v.name
      cidr = v.address_prefixes
    }
  }
}

/* Provides simplified lookup (app/db → subnet ID), unlike default outputs which use full keys like "spoke-app"
Example: { app = "/subscriptions/.../subnets/app" } */
output "subnet_lookup" {
  value = {
    for k, v in azurerm_subnet.subnet :
    local.subnet_map[k].subnet_key => v.id
  }
}

# NSGs
output "nsgs" {
  value = {
    for k, v in azurerm_network_security_group.nsg :
    k => {
      id   = v.id
      name = v.name
    }
  }
}

