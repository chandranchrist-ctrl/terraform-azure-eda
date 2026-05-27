# Creates GoDaddy CNAME record pointing custom domain to Traffic Manager endpoint for global routing and failover
resource "null_resource" "cname_dns" {

  count = var.create_dns_record ? 1 : 0

  # Always triggers when TM fqdn changes
  triggers = {
    hostname = local.traffic_manager_fqdn
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$ErrorActionPreference = "Stop"

Write-Host "==================================="
Write-Host "STARTING DNS CREATION (GoDaddy)"
Write-Host "==================================="

$tmFqdn = "${local.traffic_manager_fqdn}"

Write-Host "Target FQDN: $tmFqdn"

$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$uri = "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/${var.hostname_only}"

Write-Host "API URI: $uri"

$body = "[{`"data`":`"$tmFqdn`",`"ttl`":600}]"

try {
  $response = Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -Body $body

  Write-Host "==================================="
  Write-Host "DNS CREATED SUCCESSFULLY"
  Write-Host "==================================="
  Write-Host $response
}
catch {
  Write-Host "==================================="
  Write-Host "DNS CREATION FAILED"
  Write-Host "==================================="
  Write-Host $_.Exception.Message
  throw
}

EOT
  }

  depends_on = [
    azurerm_traffic_manager_profile.traffic_manager
  ]
}

# Adds delay to allow GoDaddy CNAME DNS propagation before dependent resources continue
resource "time_sleep" "wait_for_cname_dns" {

  count = var.create_dns_record ? 1 : 0

  depends_on = [
    null_resource.cname_dns
  ]

  create_duration = "90s"
}