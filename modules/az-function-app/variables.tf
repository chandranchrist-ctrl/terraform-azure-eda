variable "function_app_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "service_plan_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vmss_api_url" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "key_vault_id" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "sql_database" {
  type = string
}

variable "sql_port" {
  type = number
}

variable "sql_secret_name" {
  type = string
}

variable "allowed_ip_rules" {
  type    = list(string)
  default = []
}