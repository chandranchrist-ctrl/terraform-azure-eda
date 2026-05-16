/* Runs PowerShell script after VM creation
Example: installs IIS, Telnet */

resource "azurerm_virtual_machine_extension" "vm_init" {
  for_each = toset(local.vm_names)

  name               = "${each.key}-init"
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id

  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    # commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client -ErrorAction Stop\""
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client; New-NetFirewallRule -DisplayName 'SQL Server 1433' -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow\""
  })
}

# ------------------------------------------------------------
# Azure Monitor Agent (AMA) installation on Windows VM
# ------------------------------------------------------------
# PURPOSE:
# - Installs monitoring agent inside the VM
# - Required ONLY if you plan to send logs/metrics later
# - Does NOT send data by itself (needs DCR + Log Analytics)
#
# NOTE:
# - Safe to install on running VM (no reboot required)
# - Can be removed anytime without affecting VM
# ------------------------------------------------------------

# Azure Monitor Agent (AMA)
# Installs monitoring agent only (no logs collected yet)

resource "azurerm_virtual_machine_extension" "ama" {
  for_each = toset(local.vm_names)

  name               = "${each.key}-ama"
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id

  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"

  auto_upgrade_minor_version = true

  settings = jsonencode({})

  depends_on = [
    azurerm_virtual_machine_extension.vm_init
  ]
}