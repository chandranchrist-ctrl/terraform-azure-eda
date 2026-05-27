# Initializes VMSS instances with IIS, SSL bindings, and required Windows features using Custom Script Extension
resource "azurerm_virtual_machine_scale_set_extension" "vmss_init" {

  name = "${var.vmss_name}-init-v6"

  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id

  publisher = "Microsoft.Compute"

  type = "CustomScriptExtension"

  type_handler_version = "1.10"

  settings = jsonencode({

    # Installs IIS/Telnet, configures HTTPS bindings, and maps internal/public SSL certificates
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client; Install-WindowsFeature Web-Server -IncludeManagementTools; Import-Module WebAdministration; Start-Sleep -Seconds 30; $internalCert = Get-ChildItem Cert:\\LocalMachine\\My | Where-Object { $_.DnsNameList -like '*${var.private_dns_zone_name}*' } | Select-Object -First 1; $publicCert = Get-ChildItem Cert:\\LocalMachine\\My | Where-Object { $_.DnsNameList -like '*${var.public_domain}*' } | Select-Object -First 1; $internalFqdn='${var.api_dns_name}.${var.private_dns_zone_name}'; $publicFqdn='${var.api_dns_name}.${var.public_domain}'; if ($internalCert) { New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443 -HostHeader $internalFqdn -SslFlags 1; New-Item IIS:\\SslBindings\\0.0.0.0!443!$internalFqdn -Thumbprint $internalCert.Thumbprint -SSLFlags 1 }; if ($publicCert) { New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443 -HostHeader $publicFqdn -SslFlags 1; New-Item IIS:\\SslBindings\\0.0.0.0!443!$publicFqdn -Thumbprint $publicCert.Thumbprint -SSLFlags 1 }; iisreset\""

    # Optional lightweight IIS installation without SSL binding configuration
    # commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client -ErrorAction Stop; Install-WindowsFeature Web-Server -IncludeManagementTools -ErrorAction Stop\""
  })

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_role_assignment.vmss_kv_secret_user
  ]
}

# Installs Azure Monitor Agent (AMA) on VMSS instances for monitoring and telemetry collection
resource "azurerm_virtual_machine_scale_set_extension" "vmss_ama" {
  name                         = "${var.vmss_name}-ama"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id

  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"

  auto_upgrade_minor_version = true

  settings = jsonencode({})

  depends_on = [
    azurerm_virtual_machine_scale_set_extension.vmss_init
  ]
}