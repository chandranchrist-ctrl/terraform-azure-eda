variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku_tier" {
  type    = string
  default = "Standard"
}

variable "sku_size" {
  type    = string
  default = "Standard"
}

variable "api_url" {
  type = string
}

variable "custom_domain" {
  type = string
}

variable "domain" {
  type = string
}

variable "hostname_only" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "godaddy_secret_name" {
  type = string
}

variable "tm_custom_domain" {
  type    = string
  default = null
}