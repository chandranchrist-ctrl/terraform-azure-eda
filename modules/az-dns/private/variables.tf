# Network - DNS Zones
variable "zones" {
  description = "List of private DNS zones"
  type        = list(string)
}

# Core
variable "resource_group_name" {
  type = string
}

# Network - VNet Links
variable "vnet_ids" {
  description = "List of VNet IDs to link DNS zones"
  type        = list(string)
}