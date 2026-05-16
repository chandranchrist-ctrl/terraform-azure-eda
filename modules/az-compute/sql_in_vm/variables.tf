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


#VM Configuration Variables
variable "vm_name" {
  description = "Name for the VM"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "vm_size" {}

variable "subnet_id" {}

variable "ip_config_name" {
  default = "internal"
}

variable "private_ip_allocation" {
  type = string
}

variable "os_disk_storage_type" {}

variable "os_disk_size_gb" {
  type = number
}

# variable "image_sku" {}

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

variable "zones" {
  type    = list(string)
  default = []
}

variable "enable_public_ip" {
  type = bool
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

variable "availability_set_name" {
  type = string
}

variable "enable_availability_set" {
  type    = bool
  default = true
}

variable "enable_boot_diagnostics" {
  type    = bool
  default = false
}

variable "boot_diagnostics_storage_account_name" {
  type    = string
  default = null
}

variable "boot_diagnostics_mode" {
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "existing", "none"], var.boot_diagnostics_mode)
    error_message = "boot_diagnostics_mode must be create, existing, or none"
  }
}

variable "key_vault_id" {
  type = string
}

variable "enable_backup" {
  type    = bool
  default = false
}

variable "recovery_services_vault_name" {
  type = string
}

variable "backup_policy_vm" {
  type = string
}

variable "enable_asg" {
  type    = bool
  default = false
}

variable "localadmin_credentials_secret_name" {
  type = string
}

variable "license_type" {
  type    = string
  default = null
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


variable "lb_attach_map" {
  type    = map(string)
  default = {}
}

variable "internal_zone_name" {
  type = string
}