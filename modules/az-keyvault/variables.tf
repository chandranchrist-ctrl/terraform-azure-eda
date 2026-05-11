# Core
variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Security - Key Vault Config
variable "sku_name" {
  type = string
}

variable "soft_delete_retention_days" {
  type = number
}

variable "purge_protection_enabled" {
  type = bool
}

variable "enabled_for_deployment" {
  type = bool
}

variable "enabled_for_template_deployment" {
  type = bool
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable or disable public network access to the Key Vault"
}

variable "network_acls_default_action" {
  type = string
}

variable "rbac_authorization_enabled" {
  type = bool
}

# Network
variable "allowed_ip_ranges" {
  type = list(string)
}

variable "allowed_subnet_ids" {
  type = list(string)
}

# Security - Certificates
variable "certificates" {
  type = list(object({
    name     = string
    pfx_path = string
    password = string
  }))
}

# Security - Secrets
variable "secrets" {
  type = map(string)
}

# Security - SSH
variable "ssh_public_key" {
  type = string
}

variable "ssh_secret_name" {
  type    = string
  default = "linux-ssh-public-key"
}

# Security - Key
variable "tde_key_name" {
  type    = string
  default = "sql-tde-key"
}

variable "acr_key_name" {
  type    = string
  default = "acr-cmk-key"
}


# Monitoring
variable "audit_storage_account_name" {
  type = string
}

variable "audit_storage_account_rg" {
  type = string
}

# Access
variable "create_access_policy_me" {
  description = "Create access policy for current user"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "private_subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "owner_group_id" {
  type = string
}

variable "devops_group_id" {
  type = string
}