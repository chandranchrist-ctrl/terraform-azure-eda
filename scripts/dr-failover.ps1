<#
cmds to execute this script:

Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
cd D:\Mine\Course\Simplilearn\Terraform\Projects\terraform-azure-eda\scripts
.\dr-failover.ps1
#>

$ErrorActionPreference = "Stop"

# =====================================================
# VARIABLES
# =====================================================

$subscriptionId = "e5e41cc7-7577-47be-a02d-3294887037d2"

$customDomain = "eda.hbcdev.co.in"

$domain = "hbcdev.co.in"
$hostName = "eda"

$trafficManagerFqdn = "eda-ui.trafficmanager.net"

# Traffic Manager
$trafficManagerProfile = "prd-eda-tm"
$primaryEndpointName  = "primary-swa"
$drEndpointName       = "dr-swa"

# PRIMARY
$primaryRg  = "prd-rg"
$primarySwa = "prd-eda-swa-r1"

# DR
$drRg  = "dr-rg"
$drSwa = "dr-eda-swa-r2"

# GoDaddy
$godaddyKey    = "hkHptCfQoPVe_GLheXScX4sHsSsNBu2Y3qj"
$godaddySecret = "ECkifJCPVySofRBCAqjG2Y"

# =====================================================
# LOGIN
# =====================================================

az account set --subscription $subscriptionId

# =====================================================
# GET DR SWA HOSTNAME
# =====================================================

Write-Host "Fetching DR SWA hostname..."

$drHostname = az staticwebapp show `
  --name $drSwa `
  --resource-group $drRg `
  --query "defaultHostname" `
  -o tsv

Write-Host "DR SWA Hostname: $drHostname"

# =====================================================
# DISABLE PRIMARY TRAFFIC MANAGER ENDPOINT
# =====================================================

Write-Host "=========================================="
Write-Host "DISABLING PRIMARY TM ENDPOINT"
Write-Host "=========================================="

az network traffic-manager endpoint update `
  --resource-group $primaryRg `
  --profile-name $trafficManagerProfile `
  --name $primaryEndpointName `
  --type externalEndpoints `
  --endpoint-status Disabled `
  --output table

if ($LASTEXITCODE -ne 0) {
    throw "FAILED: Unable to disable PRIMARY TM endpoint."
}

$status = az network traffic-manager endpoint show `
  --resource-group $primaryRg `
  --profile-name $trafficManagerProfile `
  --name $primaryEndpointName `
  --type externalEndpoints `
  --query "endpointStatus" `
  -o tsv

if ($LASTEXITCODE -ne 0 -or $status -ne "Disabled") {
    throw "FAILED: PRIMARY TM endpoint is still enabled."
}

Write-Host "PRIMARY TM endpoint disabled successfully."

# =====================================================
# REMOVE DOMAIN FROM PRIMARY SWA
# =====================================================

Write-Host "Removing domain from PRIMARY SWA..."

az staticwebapp hostname delete `
  --hostname $customDomain `
  --name $primarySwa `
  --resource-group $primaryRg `
  --yes

if ($LASTEXITCODE -ne 0) {
    throw "FAILED: Could not delete custom domain from PRIMARY SWA."
}

Write-Host "Primary custom domain removed."

# =====================================================
# TEMPORARY DNS SWAP TO DR SWA
# =====================================================

$headers = @{
  Authorization = "sso-key $godaddyKey`:$godaddySecret"
  "Content-Type" = "application/json"
}

$uri = "https://api.godaddy.com/v1/domains/$domain/records/CNAME/$hostName"

Write-Host "Pointing DNS temporarily to DR SWA..."

$tempBody = "[{`"data`":`"$drHostname`",`"ttl`":600}]"

Invoke-RestMethod `
  -Method PUT `
  -Uri $uri `
  -Headers $headers `
  -Body $tempBody

Write-Host "Temporary validation DNS updated."

# =====================================================
# WAIT FOR DOMAIN RELEASE FROM PRIMARY SWA
# =====================================================

Write-Host "Waiting for domain release from PRIMARY SWA..."

$released = $false

for ($i = 1; $i -le 20; $i++) {

    Start-Sleep -Seconds 30

    $check = az staticwebapp hostname show `
        --name $primarySwa `
        --resource-group $primaryRg `
        --hostname $customDomain 2>$null

    if ($LASTEXITCODE -ne 0 -or -not $check) {
        Write-Host "Domain fully released from PRIMARY SWA"
        $released = $true
        break
    }

    Write-Host "Still attached to PRIMARY SWA... retry $i/20"
}

if (-not $released) {
    throw "FAILED: Domain not released from PRIMARY SWA in expected time."
}

# =====================================================
# ADD DOMAIN TO DR SWA
# =====================================================

Write-Host "Attaching domain to DR SWA..."

$attached = $false

for ($i = 1; $i -le 15; $i++) {

    Write-Host "Attempt $i of 15..."

    az staticwebapp hostname set `
        --hostname $customDomain `
        --name $drSwa `
        --resource-group $drRg

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Domain attached successfully."
        $attached = $true
        break
    }

    Write-Host "Attach failed (domain locked or DNS not ready). Retrying in 60s..."
    Start-Sleep -Seconds 60
}

if (-not $attached) {
    throw "FAILED: Domain could not be attached to DR SWA after retries."
}

# =====================================================
# RESTORE TRAFFIC MANAGER DNS (ONLY ON SUCCESS)
# =====================================================

Write-Host "Restoring Traffic Manager DNS..."

$restoreBody = "[{`"data`":`"$trafficManagerFqdn`",`"ttl`":600}]"

Invoke-RestMethod `
  -Method PUT `
  -Uri $uri `
  -Headers $headers `
  -Body $restoreBody

Write-Host "Traffic Manager DNS restored."

# =====================================================
# COMPLETED
# =====================================================

Write-Host ""
Write-Host "=========================================="
Write-Host "DR FAILOVER COMPLETED SUCCESSFULLY"
Write-Host "=========================================="