# Core
variable "env" {
  description = "Prefix for route table names"
  type        = string
}

variable "workload" {
  type = string
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

variable "name" {
  type = string
}

variable "os_type" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "zone_balancing_enabled" {
  type    = bool
  default = false
}