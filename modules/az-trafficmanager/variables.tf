variable "traffic_manager_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "traffic_routing_method" {
  type = string
}

variable "dns_relative_name" {
  type = string
}

variable "ttl" {
  type = number
}

variable "monitor_protocol" {
  type = string
}

variable "monitor_port" {
  type = number
}

variable "monitor_path" {
  type = string
}

variable "primary_target" {
  type    = string
  default = null
}

variable "dr_target" {
  type    = string
  default = null
}

variable "primary_static_web_app_id" {
  type    = string
  default = null
}

variable "dr_static_web_app_id" {
  type    = string
  default = null
}

variable "enable_dr" {
  type = bool
}

variable "create_traffic_manager" {
  type = bool
}

variable "create_primary_endpoint" {
  type = bool
}

variable "create_dns_record" {
  type = bool
}

variable "domain" {
  type = string
}

variable "hostname_only" {
  type = string
}

variable "key_vault_id" {
  type    = string
  default = null
}

variable "godaddy_secret_name" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
}

variable "validation_dependency" {
  type    = string
  default = null
}

variable "primary_endpoint_name" {
  type    = string
  default = null
}

variable "primary_endpoint_location" {
  type    = string
  default = null
}

variable "primary_swa_priority" {
  type    = number
  default = null
}

variable "primary_swa_enabled" {
  type    = bool
  default = null
}

variable "dr_endpoint_name" {
  type    = string
  default = null
}

variable "dr_endpoint_location" {
  type    = string
  default = null
}

variable "dr_swa_priority" {
  type    = number
  default = null
}

variable "dr_swa_enabled" {
  type    = bool
  default = null
}