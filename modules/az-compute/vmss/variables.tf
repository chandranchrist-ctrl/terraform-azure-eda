variable "env" {
  type = string
}

variable "workload" {
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

variable "vmss_name" {
  type = string
}

variable "instances" {
  type    = number
  default = 2
}

variable "vm_size" {
  type = string
}

variable "upgrade_mode" {
  type    = string
  default = "Automatic"
}

variable "license_type" {
  type    = string
  default = null
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "subnet_id" {
  type = string
}

variable "private_ip_allocation" {
  type    = string
  default = "Dynamic"
}

variable "enable_public_ip" {
  type    = bool
  default = false
}

variable "enable_lb" {
  type    = bool
  default = false
}

variable "lb_backend_pool_id" {
  type    = string
  default = null
}

variable "lb_name" {
  type    = string
  default = null
}

variable "lb_backend_pool_name" {
  type    = string
  default = null
}

variable "enable_asg" {
  type    = bool
  default = false
}

variable "key_vault_id" {
  type = string
}

variable "localadmin_credentials_secret_name" {
  type = string
}

variable "enable_boot_diagnostics" {
  type    = bool
  default = false
}

variable "boot_diagnostics_mode" {
  type    = string
  default = "none"
}

variable "boot_diagnostics_storage_account_name" {
  type    = string
  default = null
}

variable "os_disk_storage_type" {
  type = string
}

variable "os_disk_size_gb" {
  type = number
}

variable "data_disks" {
  type = list(object({
    size_gb      = number
    lun          = number
    caching      = string
    storage_type = string
  }))
  default = []
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "enable_backup" {
  type    = bool
  default = false
}

variable "enable_autoscale" {
  type    = bool
  default = false
}

variable "autoscale_min_capacity" {
  type    = number
  default = 1
}

variable "autoscale_max_capacity" {
  type    = number
  default = 3
}

variable "autoscale_default_capacity" {
  type    = number
  default = 1
}

variable "autoscale_cpu_scale_out_threshold" {
  type    = number
  default = 70
}

variable "autoscale_cpu_scale_in_threshold" {
  type    = number
  default = 30
}

variable "autoscale_cooldown" {
  type    = string
  default = "PT5M"
}

variable "enable_autoscale_notifications" {
  type    = bool
  default = false
}

variable "autoscale_notification_email" {
  type    = string
  default = null
}

variable "certificate_secret_url" {
  type        = string
  description = "Key Vault certificate secret URL"
}

variable "enable_dns_record" {
  type    = bool
  default = false
}

variable "private_dns_zone_name" {
  type = string
}

variable "lb_private_ip" {
  type = string
}

variable "api_dns_name" {
  type = string
}