# Network - VNet Peering
variable "peerings" {
  description = "Map of VNet peerings to create"
  type = map(object({
    name                    = string
    resource_group          = string
    vnet_name               = string
    remote_vnet_id          = string
    allow_vnet_access       = bool
    allow_forwarded_traffic = bool
    allow_gateway_transit   = bool
    use_remote_gateways     = bool
  }))
}