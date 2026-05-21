# =========================
# SQL Server Setup
# Mixed Mode + Login + Restart
# =========================

Write-Host "Starting SQL Mixed Mode configuration..." -ForegroundColor Green

# SQL details
$sqlLogin = "sqladmin"
$sqlPassword = "SQLP@ssword!23!"

# =========================
# FIND SQL INSTANCE
# =========================

$instance = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"

$instanceName = $instance.PSObject.Properties |
Where-Object { $_.Name -ne "PSPath" -and $_.Name -ne "PSParentPath" -and $_.Name -ne "PSChildName" -and $_.Name -ne "PSDrive" -and $_.Name -ne "PSProvider" } |
Select-Object -First 1

$instanceKey = $instanceName.Value
$serviceName = if ($instanceName.Name -eq "MSSQLSERVER") {
    "MSSQLSERVER"
} else {
    "MSSQL`$$($instanceName.Name)"
}

Write-Host "Detected Instance: $($instanceName.Name)"
Write-Host "Registry Key: $instanceKey"

# =========================
# ENABLE MIXED MODE
# =========================

$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\MSSQLServer"

Set-ItemProperty -Path $regPath -Name "LoginMode" -Value 2

Write-Host "Mixed Mode registry updated."

# =========================
# RESTART SQL SERVICE
# =========================

Restart-Service -Name $serviceName -Force

Start-Sleep -Seconds 15

Write-Host "SQL Service restarted."

# =========================
# VERIFY
# =========================

sqlcmd -E -S localhost -Q "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS AuthMode"

Write-Host ""
Write-Host "0 = Mixed Mode Enabled"
Write-Host "1 = Windows Authentication Only"

# =========================
# CREATE LOGIN
# =========================

$query = @"
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = '$sqlLogin')
BEGIN
    CREATE LOGIN [$sqlLogin]
    WITH PASSWORD = '$sqlPassword',
    CHECK_POLICY = OFF,
    CHECK_EXPIRATION = OFF;

    ALTER SERVER ROLE sysadmin ADD MEMBER [$sqlLogin];
END
"@

sqlcmd -E -S localhost -Q $query

Write-Host "SQL Login created."