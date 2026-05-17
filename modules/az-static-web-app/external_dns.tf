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