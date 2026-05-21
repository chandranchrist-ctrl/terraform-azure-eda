variable "logic_app_name" {
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

variable "notification_emails" {
  type = list(string)
}

variable "subscription_id" {
  type = string
}

variable "gmail_api_connection_id" {
  type = string
}

variable "gmail_api_connection_name" {
  type = string
}