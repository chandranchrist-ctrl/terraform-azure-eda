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
  type    = map(string)
  default = {}
}

variable "subnet_ids" {
  type = map(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_public_ip" {
  type    = bool
  default = true
}

variable "enable_public_ip_prefix" {
  type    = bool
  default = false
}

variable "public_ip_prefix_id" {
  type    = string
  default = null
}