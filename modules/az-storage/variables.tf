# Core
variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Storage - Configuration
variable "account_kind" {
  type = string
}
variable "account_tier" {
  type = string
}
variable "replication_type" {
  type = string
}
variable "dns_endpoint_type" {
  type = string
}
variable "public_network_access" {
  type = bool
}

# Storage - Data Protection
variable "blob_versioning_enabled" {
  type = bool
}

variable "container_delete_retention_days" {
  type = number
}

variable "blob_delete_retention_days" {
  type = number
}

# Storage - Network
variable "allowed_subnet_ids" {
  type = list(string)
}

variable "allowed_ip_rules" {
  type = list(string)
}


# Storage - Lifecycle
variable "lifecycle_rules" {
  type = list(object({
    name   = string
    prefix = list(string)
    days   = number
  }))
  default = []
}

# Storage - Containers
variable "containers" {
  type    = list(string)
  default = []
}

variable "enable_sas" {
  type    = bool
  default = true
}