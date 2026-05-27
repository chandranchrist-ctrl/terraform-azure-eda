# =========================
# SQL Server Setup Script
# Mixed Mode + Login + DB + User Mapping
# =========================

Write-Host "Starting SQL Server configuration..." -ForegroundColor Green

# Config
$sqlLogin = "sqladmin"
$sqlPassword = "SQLP@ssword!23!"
$dbName = "OrdersDB"

# Find SQL Instance
$instance = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"

$instanceName = $instance.PSObject.Properties |
Where-Object {
    $_.Name -notlike "PS*"
} |
Select-Object -First 1

$instanceKey = $instanceName.Value

$serviceName = if ($instanceName.Name -eq "MSSQLSERVER") {
    "MSSQLSERVER"
} else {
    "MSSQL`$$($instanceName.Name)"
}

Write-Host "Detected Instance: $($instanceName.Name)"
Write-Host "Registry Key: $instanceKey"

# Enable Mixed Mode
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\MSSQLServer"

Set-ItemProperty -Path $regPath -Name "LoginMode" -Value 2

Write-Host "Mixed Mode enabled."

# Restart SQL Service
Restart-Service -Name $serviceName -Force
Start-Sleep -Seconds 20

Write-Host "SQL Service restarted."

# Verify Auth Mode
sqlcmd -E -S localhost -Q "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS AuthMode"

Write-Host "0 = Mixed Mode | 1 = Windows Only"

# Create SQL Login
$queryLogin = @"
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = '$sqlLogin')
BEGIN
    CREATE LOGIN [$sqlLogin]
    WITH PASSWORD = '$sqlPassword',
    CHECK_POLICY = OFF,
    CHECK_EXPIRATION = OFF;

    ALTER SERVER ROLE sysadmin ADD MEMBER [$sqlLogin];
END
"@

sqlcmd -E -S localhost -Q $queryLogin

Write-Host "SQL Login created."

# Create Database
$queryDb = @"
IF DB_ID('$dbName') IS NULL
BEGIN
    CREATE DATABASE [$dbName];
END
"@

sqlcmd -E -S localhost -Q $queryDb

Write-Host "Database [$dbName] ready."

# Create DB User + Permissions
$queryUser = @"
USE [$dbName];

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$sqlLogin')
BEGIN
    CREATE USER [$sqlLogin] FOR LOGIN [$sqlLogin];
END

ALTER ROLE db_owner ADD MEMBER [$sqlLogin];
"@

sqlcmd -E -S localhost -Q $queryUser

Write-Host "User mapped and permissions assigned."

# Completed
Write-Host "SQL setup completed successfully." -ForegroundColor Green