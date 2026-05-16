resource "azurerm_public_ip" "pip" {
  for_each = var.enable_public_ip ? toset(local.vm_names) : toset([])

  name                = "${each.key}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}


/* Creates NIC per VM
Attaches public IP only if enable_public_ip = true */
resource "azurerm_network_interface" "nic" {
  for_each = toset(local.vm_names)

  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.ip_config_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_allocation

    public_ip_address_id = var.enable_public_ip ? azurerm_public_ip.pip[each.key].id : null
  }
  tags = var.tags
}

/* Creates Application Security Group per VM;
Used for NSG rules instead of IP-based rules */
resource "azurerm_application_security_group" "asg" {
  for_each = var.enable_asg ? toset(local.vm_names) : toset([])

  name                = "${each.key}-asg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "asg_attach" {
  for_each = var.enable_asg ? azurerm_network_interface.nic : {}

  network_interface_id = each.value.id

  application_security_group_id = azurerm_application_security_group.asg[each.key].id
}

/* Attaches NIC to LB backend pool
Works with existing or provided backend pool */
resource "azurerm_network_interface_backend_address_pool_association" "lb" {
  for_each = var.enable_lb ? azurerm_network_interface.nic : {}

  network_interface_id  = each.value.id
  ip_configuration_name = var.ip_config_name

  backend_address_pool_id = (
    var.lb_backend_pool_id != null
    ? var.lb_backend_pool_id
    : data.azurerm_lb_backend_address_pool.existing[0].id
  )
}


/* Groups VMs for high availability (fault + update domains)
Used only when zones are not configured */
resource "azurerm_availability_set" "avset" {
  count = var.enable_availability_set ? 1 : 0

  name                = coalesce(var.availability_set_name, "${var.vm_name}-avset")
  location            = var.location
  resource_group_name = var.resource_group_name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 3
  managed                      = true

  tags = var.tags
}


/* Creates storage account only if mode = "create"
Skipped for "existing" or "none" */
locals {
  use_boot_diag   = var.boot_diagnostics_mode != "none"
  use_existing_sa = var.boot_diagnostics_mode == "existing"
  use_create_sa   = var.boot_diagnostics_mode == "create"
}

resource "azurerm_storage_account" "diag" {
  count = local.use_create_sa ? 1 : 0

  name = coalesce(
    var.boot_diagnostics_storage_account_name,
    substr("${lower(replace(var.vm_name, "-", ""))}diag", 0, 24)
  )

  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

/* Generates VM names like: vm01, vm02, vm03...
Based on vm_count */
locals {
  vm_names = [
    for i in range(var.vm_count) :
    format("%s%02d", var.vm_name, i + 1)
  ]

  zones = var.zones != null ? var.zones : []

  vm_zone_map = length(local.zones) > 0 ? {
    for i, name in local.vm_names :
    name => element(local.zones, i % length(local.zones))
  } : {}
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = toset(local.vm_names)

  name                = each.key
  computer_name       = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  admin_username = local.localadmin_creds.admin-username
  admin_password = local.localadmin_creds.admin-password

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  availability_set_id = (
    var.enable_availability_set && length(local.zones) == 0
    ? azurerm_availability_set.avset[0].id
    : null
  )

  zone = length(local.zones) > 0 ? local.vm_zone_map[each.key] : null

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # source_image_reference {
  #   publisher = "MicrosoftWindowsServer"
  #   offer     = "WindowsServer"
  #   sku       = var.image_sku
  #   version   = "latest"
  # }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  license_type = var.license_type

  boot_diagnostics {
    storage_account_uri = local.use_boot_diag ? (
      local.use_existing_sa
      ? data.azurerm_storage_account.diag[0].primary_blob_endpoint
      : azurerm_storage_account.diag[0].primary_blob_endpoint
    ) : null
  }


  /* Enables System Assigned Managed Identity
Used for accessing Azure services (Key Vault, Storage, etc.) */
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}


/* Creates and attaches data disks to VM
Supports multiple disks using LUN(Logical Unit Number) mapping - Uniquely identifies each data disk attached to a VM */
locals {
  data_disks = {
    for pair in setproduct(local.vm_names, var.data_disks) :
    "${pair[0]}-${pair[1].lun}" => {
      vm   = pair[0]
      disk = pair[1]
    }
  }
}

resource "azurerm_managed_disk" "data_disk" {
  for_each = local.data_disks

  name                = "${each.value.vm}-datadisk${each.value.disk.lun}"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_type = each.value.disk.storage_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk.size_gb

  zone = length(local.zones) > 0 ? local.vm_zone_map[each.value.vm] : null
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.value.vm].id

  lun     = each.value.disk.lun
  caching = each.value.disk.caching

  depends_on = [
    azurerm_windows_virtual_machine.vm,
    azurerm_managed_disk.data_disk
  ]
}


/* Protects VM using Recovery Services Vault
Created only when enable_backup = true */
resource "azurerm_backup_protected_vm" "vm_backup" {
  for_each = var.enable_backup ? azurerm_windows_virtual_machine.vm : {}

  resource_group_name = var.resource_group_name

  source_vm_id        = each.value.id
  backup_policy_id    = data.azurerm_backup_policy_vm.policy[0].id
  recovery_vault_name = data.azurerm_recovery_services_vault.vault[0].name
}
