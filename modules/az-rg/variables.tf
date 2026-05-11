variable "env" {
  type = string
}

# Resource Group
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create"
}

variable "resource_group_location" {
  type        = string
  description = "Azure region where the resource group will be created"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to the resource group"
  default     = {}
}