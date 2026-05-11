locals {
  # Define NSG rules for each subnet
  # Key format: "<vnet_key>-<subnet_key>" (must match NSG map keys)
  nsg_rules = {
    # Rules for app subnet (example: allow RDP or SSH traffic)
    "hub_vnet-snet_mgmt" = [
      {
        name                   = "allow-rdp-ssh"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "3389"
        destination_port_range = "*"

        source_address_prefix      = "var.jhost_allowed_sources"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      }
    ]

    "app_svnet-snet_vmss" = [
      {
        name                   = "allow-https"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "443"
        destination_port_range = "443"

        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      }
    ]


    # Rules for database subnet (example: allow MYSQL traffic)
    "data_svnet-snet_db" = [
      {
        name      = "allow-mysql"
        priority  = 100
        direction = "Inbound"
        access    = "Allow"
        protocol  = "Tcp"
        source_address_prefixes = [
          "172.16.1.0/24" # VMSS CIDR
        ]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "3306"
        source_asg                 = null
        dest_asg                   = null
      },
    ]
  }
}