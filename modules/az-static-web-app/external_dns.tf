# CNAME DNS Record
resource "null_resource" "cname_dns" {

  triggers = {
    hostname = azurerm_static_web_app.static_web_app.default_host_name
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$body = '[{"data":"${azurerm_static_web_app.static_web_app.default_host_name}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/${var.hostname_only}" `
  -Headers $headers `
  -Body $body

EOT
  }
}

# Custom Domain Resource
resource "azurerm_static_web_app_custom_domain" "custom_domain" {

  static_web_app_id = azurerm_static_web_app.static_web_app.id

  domain_name = var.custom_domain

  validation_type = "cname-delegation"

  depends_on = [
    time_sleep.wait_for_cname_dns
  ]
}

# TEMP TM DOMAIN VALIDATION DNS
# eda.hbcdev.co.in -> swa default hostname
resource "null_resource" "tm_validation_dns" {

  count = var.tm_custom_domain != null ? 1 : 0

  triggers = {
    hostname = azurerm_static_web_app.static_web_app.default_host_name
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

Write-Host "==================================="
Write-Host "CREATING TM VALIDATION DNS"
Write-Host "==================================="

$body = '[{"data":"${azurerm_static_web_app.static_web_app.default_host_name}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/eda" `
  -Headers $headers `
  -Body $body

Write-Host "TM VALIDATION DNS CREATED"

EOT
  }

  depends_on = [
    azurerm_static_web_app_custom_domain.custom_domain
  ]
}



# ATTACH TM DOMAIN TO SWA
# eda.hbcdev.co.in
resource "azurerm_static_web_app_custom_domain" "tm_domain" {

  count = var.tm_custom_domain != null ? 1 : 0

  static_web_app_id = azurerm_static_web_app.static_web_app.id

  domain_name = var.tm_custom_domain

  validation_type = "cname-delegation"

  depends_on = [
    time_sleep.wait_for_tm_validation_dns[0]
  ]
}

# REMOVE TEMP VALIDATION DNS
resource "null_resource" "remove_tm_validation_dns" {

  count = var.tm_custom_domain != null ? 1 : 0

  depends_on = [
    time_sleep.wait_for_tm_ssl
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

Write-Host "==================================="
Write-Host "REMOVING TM VALIDATION DNS"
Write-Host "==================================="

Invoke-RestMethod -Method Delete `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/eda" `
  -Headers $headers

Write-Host "TM VALIDATION DNS REMOVED"

EOT
  }
}