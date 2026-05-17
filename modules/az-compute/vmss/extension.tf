resource "azurerm_virtual_machine_scale_set_extension" "vmss_init" {

  name = "${var.vmss_name}-init-v6"

  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id

  publisher = "Microsoft.Compute"

  type = "CustomScriptExtension"

  type_handler_version = "1.10"

  settings = jsonencode({

    # Below cmd include iis binding for 443 with ssl
    # commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client; Install-WindowsFeature Web-Server -IncludeManagementTools; Import-Module WebAdministration; Start-Sleep -Seconds 30; $cert = Get-ChildItem Cert:\\LocalMachine\\My | Where-Object { $_.Subject -like '*hbcdev.co.in*' } | Select-Object -First 1; if ($cert) { New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443 -IPAddress '*'; Push-Location IIS:\\SslBindings; if (Get-Item '0.0.0.0!443' -ErrorAction SilentlyContinue) { Remove-Item '0.0.0.0!443' -Force }; New-Item '0.0.0.0!443' -Thumbprint $($cert.Thumbprint) -SSLFlags 0; Pop-Location; iisreset }\""

    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client; Install-WindowsFeature Web-Server -IncludeManagementTools; Import-Module WebAdministration; Start-Sleep -Seconds 30; $fqdn='uat-eda-api.internal.hbcdev.co.in'; $cert = Get-ChildItem Cert:\\LocalMachine\\My | Where-Object { $_.DnsNameList -like '*internal.hbcdev.co.in*' } | Select-Object -First 1; if ($cert) { New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443 -HostHeader $fqdn -SslFlags 1;  New-Item IIS:\\SslBindings\\0.0.0.0!443!$fqdn -Thumbprint $cert.Thumbprint -SSLFlags 1; iisreset }\""
    # Below cmd helps to install onle telnet client and web server without ssl binding
    # commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Telnet-Client -ErrorAction Stop; Install-WindowsFeature Web-Server -IncludeManagementTools -ErrorAction Stop\""
  })

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_role_assignment.vmss_kv_secret_user
  ]
}

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