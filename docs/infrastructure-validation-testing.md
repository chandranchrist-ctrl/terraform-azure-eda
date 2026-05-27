# Infrastructure Validation & Testing Report (EDA Architecture)

## Overview
This document defines the complete infrastructure validation and testing approach for the EDA system.

It is grouped by execution source:
- Azure Function App Console
- VMSS Server
- Internet (External Access)

It validates:
- DNS resolution (Private DNS zones)
- Network connectivity
- Storage Queue access
- SQL connectivity
- VMSS API communication rules
- Logic App triggers
- Static Web App access
- DR readiness

---

## 1. Validation from Azure Function App Console

### 1.1 SQL VM DNS Validation

```bash
nslookup uat-eda-sql01.internal.hbcdev.co.in
nslookup dr-eda-sql01.internal.hbcdev.co.in
```

Expected Result:
1. Resolves to private IP via Private DNS zone


### 1.2 VMSS API DNS Validation

```bash
nslookup uat-eda-api.internal.hbcdev.co.in
nslookup dr-eda-api.internal.hbcdev.co.in
```

Expected Result:
2. Resolves to private/internal load balancer IP

### 1.3 SQL Network Connectivity (1433)

```bash
tcpping uat-eda-sql01.internal.hbcdev.co.in:1433
tcpping dr-eda-sql01.internal.hbcdev.co.in:1433
```

Expected Result:
1. Port 1433 is reachable
2. No firewall or NSG blocking

### 1.4 Storage Queue Reachability Validation

```bash
curl https://uatedasa19.queue.core.windows.net/orders-queue
curl https://dredasa19.queue.core.windows.net/orders-queue
```

```bash
nslookup uatedasa19.queue.core.windows.net
nslookup dredasa19.queue.core.windows.net
```

Expected Result:
1. Private endpoint resolution
2. No public access fallback
3. Access via Managed Identity

### 1.5 Logic App Connectivity Validation (Internet Trigger)

### DNS Check
```bash
nslookup prod-27.centralindia.logic.azure.com
```
### Connectivity Check

```bash
tcpping prod-27.centralindia.logic.azure.com:443
```

### Trigger Test

```bash
curl -X POST "https://prod-25.centralindia.logic.azure.com:443/workflows/d5e4ffb77a7742cb8b26f16d69fe3898/triggers/order-notification-trigger/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Forder-notification-trigger%2Frun&sv=1.0&sig=REDACTED" ^
-H "Content-Type: application/json" ^
-d "{\"orderId\":\"1001\",\"customerName\":\"John\",\"email\":\"john@gmail.com\",\"product\":\"Laptop\",\"quantity\":1,\"status\":\"Created\",\"createdDate\":\"2026-05-21\"}"
```

Expected Result:
1. Logic App triggered successfully
2. Function receives event
3. Email notification executed

### 1.6 Database Connectivity Validation (Function Console)

### PROD SQL Connection

```bash
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=tcp:uat-eda-sql01.internal.hbcdev.co.in,1433;Database=master;User Id=sqladmin;Password=********;Encrypt=True;TrustServerCertificate=True;"
$conn.Open()
$conn.State
```

### DR SQL Connection

```bash
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=tcp:dr-eda-sql01.internal.hbcdev.co.in,1433;Database=master;User Id=sqladmin;Password=********;Encrypt=True;TrustServerCertificate=True;"
$conn.Open()
$conn.State
```

Expected Result:
1. State = Open
2. No authentication or TLS errors

---

## Validation from VMSS Server

### 2.1 SQL VM DNS Validation

```bash
nslookup uat-eda-sql01.internal.hbcdev.co.in
nslookup dr-eda-sql01.internal.hbcdev.co.in
```

Expected Result:
1. DNS resolves successfully

### 2.2 SQL Network Connectivity Validation (EXPECTED TO FAIL)

```bash
telnet uat-eda-sql01.internal.hbcdev.co.in 1433
telnet dr-eda-sql01.internal.hbcdev.co.in 1433
```

Expected Result:
1. ❌ MUST FAIL

### Reason:

1. VMSS is NOT allowed to connect directly to SQL.

### Architecture rule:

```
VMSS → Function App → SQL VM
```

Direct access is blocked for:
1. Security enforcement
2. Controlled data access flow
3. Centralized processing via Function App

### 2.3 Storage Queue Reachability Validation

```bash
curl https://uatedasa19.queue.core.windows.net/orders-queue
curl https://dredasa19.queue.core.windows.net/orders-queue
```

```bash
nslookup uatedasa19.queue.core.windows.net
nslookup dredasa19.queue.core.windows.net
```

Expected Result:
1. Resolves via Private Endpoint
2. Access controlled via Managed Identity
3. No public endpoint usage

---

## Validation from Internet (External Access)

### 3.1 Static Web App Access Validation
### UAT

```bash
https://uat-eda.hbcdev.co.in/
```
### DR

```bash
https://dr-eda.hbcdev.co.in/
```

Expected Result:
1. Application loads successfully
2. Correct environment configuration

### 3.2 Production Endpoints Validation

### Traffic Manager

```bash
https://eda.hbcdev.co.in/
```

### VMSS API (Production)

```bash
https://prd-eda-api.hbcdev.co.in
https://prd-eda-api.hbcdev.co.in/health
https://prd-eda-api.hbcdev.co.in/swagger
```

### Static Web App (Production)

```bash
https://prd-eda.hbcdev.co.in/
```

### SWA Default Endpoint

```bash
https://victorious-island-065319c00.7.azurestaticapps.net
```

### 3.3 DR Endpoints Validation
### VMSS API (DR)

```bash
https://dr-eda-api.hbcdev.co.in
https://dr-eda-api.hbcdev.co.in/health
https://dr-eda-api.hbcdev.co.in/swagger
```

### Static Web App (DR)

```bash
https://dr-eda.hbcdev.co.in/
```

### SWA Default DR Endpoint

```bash
https://proud-ocean-0eca32d03.7.azurestaticapps.net
```
---

## 4. Architecture Validation Rules

### Key Rules
1. VMSS must NOT directly access SQL
2. Only Function App handles SQL communication
3. Storage Queue must use Private Endpoint resolution
4. All internal services must resolve via Private DNS zones
5. External access allowed only via public endpoints (SWA, TM, Logic App)

---

## 5. Final Validation Summary

| Component               | Source       | Expected Result     |
| ----------------------- | ------------ | ------------------- |
| SQL DNS Resolution      | Function App | Private IP          |
| VMSS API DNS            | Function App | Private/Internal IP |
| SQL Connectivity (1433) | Function App | SUCCESS             |
| Storage Queue Access    | Function App | PRIVATE ACCESS      |
| Logic App Trigger       | Function App | SUCCESS             |
| Database Connection     | Function App | OPEN                |
| SQL Access from VMSS    | VMSS         | ❌ FAIL (by design)  |
| Queue Access            | VMSS         | PRIVATE RESOLUTION  |
| Static Web App          | Internet     | SUCCESS             |
| Traffic Manager Routing | Internet     | SUCCESS             |
| DR Failover             | Internet     | SUCCESS             |

---

## 6. Conclusion

### This validation confirms:
1. Secure private network architecture
2. Proper separation of responsibilities (VMSS vs Function App)
3. Correct DNS resolution using Private Endpoints
4. End-to-end event-driven architecture flow
5. DR readiness with seamless failover capability
