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


# lb Configuration
variable "lb_name" {
  type = string
}

variable "sku" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "frontend_ip_type" {
  type = string
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "public_ip_name" {
  type    = string
  default = ""
}

variable "allocation_method" {
  type = string
}

variable "backend_address_pool_name" {
  type        = string
  description = "Default backend pool name"
  default     = "lb-backend-pool"
}

variable "private_dns_zone_name" {
  type = string
}