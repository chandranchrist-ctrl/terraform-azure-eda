locals {
  vmss_instances = [
    for i in range(var.instances) :
    format("%s%02d", var.vmss_name, i + 1)
  ]

  zones = var.zones != null ? var.zones : []

  use_boot_diag   = var.enable_boot_diagnostics
  use_existing_sa = var.boot_diagnostics_mode == "existing"
  use_create_sa   = var.boot_diagnostics_mode == "create"
}

resource "azurerm_storage_account" "diag" {
  count = local.use_create_sa ? 1 : 0

  name = substr("${var.env}${var.workload}vmssdiag", 0, 24)

  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_security_group" "asg" {
  count = var.enable_asg ? 1 : 0

  name                = "${var.vmss_name}-asg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku       = var.vm_size
  instances = var.instances

  computer_name_prefix = var.vmss_name

  admin_username = local.localadmin_creds.admin-username
  admin_password = local.localadmin_creds.admin-password

  upgrade_mode = var.upgrade_mode
  license_type = var.license_type

  identity {
    type = "SystemAssigned"
  }

  zones = length(local.zones) > 0 ? local.zones : null

  os_disk {
    storage_account_type = var.os_disk_storage_type
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # secret {

  #   key_vault_id = var.key_vault_id

  #   certificate {

  #     store = "My"

  #     url = var.certificate_secret_url
  #   }
  # }

  secret {

    key_vault_id = var.key_vault_id

    certificate {
      store = "My"
      url   = var.certificate_priv_secret_url
    }

    certificate {
      store = "My"
      url   = var.certificate_pub_secret_url
    }
  }

  network_interface {
    name    = "${var.vmss_name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = var.subnet_id

      # load_balancer_backend_address_pool_ids = var.enable_lb ? [
      #   local.lb_backend_pool_id
      # ] : []

      load_balancer_backend_address_pool_ids = var.enable_lb ? local.lb_backend_pool_ids : []

      application_security_group_ids = var.enable_asg && length(azurerm_application_security_group.asg) > 0 ? [
        azurerm_application_security_group.asg[0].id
      ] : []

      dynamic "public_ip_address" {
        for_each = var.enable_public_ip ? [1] : []

        content {
          name = "${var.vmss_name}-pip"
        }
      }
    }
  }

  boot_diagnostics {
    storage_account_uri = local.use_boot_diag ? (
      local.use_existing_sa
      ? data.azurerm_storage_account.diag[0].primary_blob_endpoint
      : azurerm_storage_account.diag[0].primary_blob_endpoint
    ) : null
  }

  dynamic "data_disk" {
    for_each = var.data_disks

    content {
      lun                  = data_disk.value.lun
      caching              = data_disk.value.caching
      disk_size_gb         = data_disk.value.size_gb
      storage_account_type = data_disk.value.storage_type
    }
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_restore_point_collection" "rpc" {
  count = var.enable_backup ? 1 : 0

  name                = "${var.vmss_name}-rpc"
  location            = var.location
  resource_group_name = var.resource_group_name

  source_virtual_machine_id = azurerm_windows_virtual_machine_scale_set.vmss.id
}