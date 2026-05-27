<# 
cmds to execute this script:

Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
cd D:\Mine\Course\Simplilearn\Terraform\Projects\terraform-azure-eda\scripts
.\dr-failback.ps1
#>

$ErrorActionPreference = "Stop"

# Variables
$subscriptionId = "e5e41cc7-7577-47be-a02d-3294887037d2"

$customDomain = "eda.hbcdev.co.in"

$domain = "hbcdev.co.in"
$hostName = "eda"

$trafficManagerFqdn = "eda-ui.trafficmanager.net"

# Traffic Manager
$trafficManagerProfile = "prd-eda-tm"
$primaryEndpointName  = "primary-swa"

# Primary
$primaryRg  = "prd-rg"
$primarySwa = "prd-eda-swa-r1"

# DR
$drRg  = "dr-rg"
$drSwa = "dr-eda-swa-r2"

# GoDaddy APIKey & Secret
$godaddyKey    = "hkHptCfQoPVe_GLheXScX4sHsSsNBu2Y3qj"
$godaddySecret = "ECkifJCPVySofRBCAqjG2Y"

# az login
az account set --subscription $subscriptionId

# Get Primary SWA Hostname
Write-Host "Fetching PRIMARY SWA hostname..."

$primaryHostname = az staticwebapp show `
  --name $primarySwa `
  --resource-group $primaryRg `
  --query "defaultHostname" `
  -o tsv

Write-Host "PRIMARY SWA Hostname: $primaryHostname"

# Remove Domain From DR SWA
Write-Host "=========================================="
Write-Host "REMOVING DOMAIN FROM DR SWA"
Write-Host "=========================================="

az staticwebapp hostname delete `
  --hostname $customDomain `
  --name $drSwa `
  --resource-group $drRg `
  --yes

if ($LASTEXITCODE -ne 0) {
    throw "FAILED: Unable to remove custom domain from DR SWA."
}

Write-Host "Custom domain removed from DR SWA successfully."

Write-Host ""
Write-Host "Waiting for Azure SWA hostname ownership release..."

Start-Sleep -Seconds 120

# Temporary DNS Swap To Primary SWA
$headers = @{
  Authorization = "sso-key $godaddyKey`:$godaddySecret"
  "Content-Type" = "application/json"
}

$uri = "https://api.godaddy.com/v1/domains/$domain/records/CNAME/$hostName"

Write-Host "Pointing DNS temporarily to PRIMARY SWA..."

$tempBody = "[{`"data`":`"$primaryHostname`",`"ttl`":600}]"

Invoke-RestMethod `
  -Method PUT `
  -Uri $uri `
  -Headers $headers `
  -Body $tempBody

Write-Host "Temporary DNS updated to PRIMARY SWA."

# Wait For Propagation
Write-Host "Waiting 120 seconds for DNS propagation..."

Start-Sleep -Seconds 120

# Attach Domain To Primary SWA
Write-Host "=========================================="
Write-Host "ATTACHING DOMAIN TO PRIMARY SWA"
Write-Host "=========================================="

$attached = $false

for ($i = 1; $i -le 15; $i++) {

    Write-Host "Attempt $i of 15..."

    az staticwebapp hostname set `
      --hostname $customDomain `
      --name $primarySwa `
      --resource-group $primaryRg

    if ($LASTEXITCODE -eq 0) {

        $attached = $true

        Write-Host "Custom domain attached successfully to PRIMARY SWA."

        break
    }

    Write-Host "Domain still locked by DR SWA."
    Write-Host "Waiting 60 seconds before retry..."

    Start-Sleep -Seconds 60
}

if (-not $attached) {

    throw "FAILED: Unable to attach custom domain to PRIMARY SWA after multiple attempts."
}

# Restora Traffic Manager DNS
Write-Host "Restoring Traffic Manager DNS..."

$restoreBody = "[{`"data`":`"$trafficManagerFqdn`",`"ttl`":600}]"

Invoke-RestMethod `
  -Method PUT `
  -Uri $uri `
  -Headers $headers `
  -Body $restoreBody

Write-Host "Traffic Manager DNS restored."

# Enable Primary TM Endpoint
Write-Host "=========================================="
Write-Host "ENABLING PRIMARY TM ENDPOINT"
Write-Host "=========================================="

az network traffic-manager endpoint update `
  --resource-group $primaryRg `
  --profile-name $trafficManagerProfile `
  --name $primaryEndpointName `
  --type externalEndpoints `
  --endpoint-status Enabled `
  --output table

if ($LASTEXITCODE -ne 0) {
    throw "FAILED: Unable to enable PRIMARY TM endpoint."
}

Write-Host ""
Write-Host "Verifying endpoint status..."

$status = az network traffic-manager endpoint show `
  --resource-group $primaryRg `
  --profile-name $trafficManagerProfile `
  --name $primaryEndpointName `
  --type externalEndpoints `
  --query "endpointStatus" `
  -o tsv

if ($LASTEXITCODE -ne 0) {
    throw "FAILED: Unable to verify PRIMARY TM endpoint status."
}

Write-Host "Current Status: $status"

if ($status -ne "Enabled") {
    throw "FAILED: PRIMARY TM endpoint is still disabled."
}

Write-Host ""
Write-Host "PRIMARY TM endpoint enabled successfully."

# Completed
Write-Host ""
Write-Host "=========================================="
Write-Host "PRIMARY FAILBACK COMPLETED SUCCESSFULLY"
Write-Host "=========================================="