# Core
variable "env" {
  type = string
}

variable "workload" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create"
}

variable "location" {
  type        = string
  description = "Azure region where the resource group will be created"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to the resource group"
  default     = {}
}

# vnet_address_space is a map of vnet names to their address spaces
variable "vnet_address_space" {
  type = map(list(string))
}

variable "subnet_address_space" {
  type = map(map(object({
    cidr = list(string)
    tags = optional(map(string), {})

    delegation = optional(object({
      name = string

      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  })))
}

# Network - Subnet Settings
variable "default_outbound_access_enabled" {
  type    = bool
  default = false
}

# Network - ASG
variable "asg_map" {
  type    = map(string)
  default = {}
}

variable "allowed_sources" {
  type    = list(string)
  default = []
}