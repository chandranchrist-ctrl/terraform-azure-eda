variable "subscription_id" {}

variable "storage_account_name" {
  type    = string
  default = ""
}
variable "key_vault_name" {
  type    = string
  default = ""
}

variable "diag_storage_account_name" {
  type = string
}

variable "appservice_storage_account_name" {
  type = string
}

variable "mssql_storage_account_name" {
  type = string
}

variable "allowed_ips" {
  description = "Allowed IPs for ACR firewall"
  type        = list(string)
  default     = []
}

variable "allowed_ips_plain" {
  description = "Allowed IPs for ACR firewall"
  type        = list(string)
  default     = []
}