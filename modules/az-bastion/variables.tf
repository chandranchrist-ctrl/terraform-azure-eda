# Core
variable "env" {
  description = "Prefix for route table names"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# Bastion Config
variable "sku" {
  type = string
}

variable "tunneling_enabled" {
  type = bool
}

variable "ip_connect_enabled" {
  type = bool
}

variable "copy_paste_enabled" {
  type = bool
}

variable "file_copy_enabled" {
  type = bool
}

variable "zones" {
  type    = list(string)
  default = null
}

variable "kerberos_enabled" {
  type = bool
}

# Network
variable "subnet_id" { /* must be AzureBastionSubnet */
  type = string
}

variable "enable_bastion" {
  type    = bool
  default = true
}