locals {
  # Define NSG rules for each subnet
  # Key format: "<vnet_key>-<subnet_key>" (must match NSG map keys)
  nsg_rules = {
    # Rules for app subnet (example: allow RDP or SSH traffic)
    "data-db" = [
      {
        name                   = "allow-rdp-ssh"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "3389"

        source_address_prefixes    = concat(var.allowed_sources, ["10.0.1.0/26"])
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                   = "allow-sql"
        priority               = 101
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "1433"

        source_address_prefixes    = var.allowed_sources
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      }
    ]

    "app-vmss" = [
      {
        name                   = "allow-rdp-ssh"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "3389"

        source_address_prefixes    = concat(var.allowed_sources, ["10.0.1.0/26"])
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                    = "allow-https"
        priority                = 101
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_port_range       = "*"
        destination_port_ranges = ["443", "80"]

        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                    = "allow-https-from-internet"
        priority                = 102
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_port_range       = "*"
        destination_port_ranges = ["443", "80"]

        source_address_prefixes    = var.allowed_sources
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                   = "deny-traffic-http-https"
        priority               = 1200
        direction              = "Inbound"
        access                 = "Deny"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "*"

        source_address_prefix      = "*"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      }
    ]
  }
}