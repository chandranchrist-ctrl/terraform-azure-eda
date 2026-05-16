# =========================
# SQL Server Setup
# Mixed Mode + Login + Restart
# =========================

Write-Host "Starting SQL Server configuration..." -ForegroundColor Green


# =========================
# 1. FIREWALL RULE (1433)
# =========================
Write-Host "Creating firewall rule..." -ForegroundColor Yellow

New-NetFirewallRule `
    -DisplayName "SQL Server TCP 1433" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 1433 `
    -Action Allow `
    -Profile Any `
    -Enabled True

Write-Host "Firewall rule created." -ForegroundColor Green


# =========================
# 2. USER INPUT
# =========================
$sqlLogin = "sqladmin"
$sqlPassword = "SQLP@ssword!23!"


# =========================
# 3. ENABLE MIXED MODE
# =========================
Write-Host "Enabling Mixed Mode authentication..." -ForegroundColor Yellow

$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer"

try {
    Set-ItemProperty -Path $regPath -Name "LoginMode" -Value 2
    Write-Host "Mixed Mode enabled." -ForegroundColor Green
}
catch {
    Write-Host "Failed to enable Mixed Mode. Run as Administrator." -ForegroundColor Red
}


# =========================
# 4. CREATE SQL LOGIN
# =========================
Write-Host "Creating SQL login..." -ForegroundColor Yellow

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

sqlcmd -Q $query

Write-Host "SQL login created." -ForegroundColor Green


# =========================
# 5. RESTART SQL SERVICE
# =========================
Write-Host "Restarting SQL Server service..." -ForegroundColor Yellow

try {
    Restart-Service MSSQLSERVER -Force -ErrorAction Stop
    Write-Host "SQL Server restarted successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to restart SQL Server. Check service name or permissions." -ForegroundColor Red
}


# =========================
# DONE
# =========================
Write-Host "SQL setup completed successfully." -ForegroundColor Green