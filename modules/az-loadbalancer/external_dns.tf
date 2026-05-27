# Creates/updates external GoDaddy DNS A record pointing domain hostname to Azure Load Balancer public IP
# GoDaddy A Record
resource "null_resource" "external_dns" {

  count = var.enable_external_dns && var.frontend_ip_type == "Public" ? 1 : 0

  triggers = {
    public_ip = azurerm_public_ip.lb_public_ip[0].ip_address
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$body = '[{"data":"${azurerm_public_ip.lb_public_ip[0].ip_address}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/A/${var.hostname_only}" `
  -Headers $headers `
  -Body $body

EOT
  }

  depends_on = [
    azurerm_public_ip.lb_public_ip
  ]
}