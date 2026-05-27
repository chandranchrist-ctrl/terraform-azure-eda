# Application Deployment + Validation Runbook (EDA Architecture)

## 1. Static Web App Frontend Deployment (static_webapp_fe)

### 1.1 Clean Previous Build

```powershell
Remove-Item -Recurse -Force .\build\
```

---

### 1.2 Build Frontend (React)

```
cd frontend
npm install
npm run build
```

### 1.3 Install Azure SWA CLI (if not installed)

```bash
npm install -g @azure/static-web-apps-cli
```

### 1.4 Local Preview (Optional Testing)

### Serve React locally

```bash
npm start
```

OR production build preview:

```bash
npx serve -s build
```

### 1.5 Local SWA Preview (Optional)

```bash
swa start ./build
```

### 1.6 Deploy to PREVIEW Environment

```bash
swa deploy ./build --deployment-token 8b06c4b78ad6aef9aa8cd7f1b40c974a368697c8f3df71c6deda4023b149bd9507-e3c3fb7f-9a0b-4dc1-80ba-2e2ced283c6a00016020fff28c00
```

### 1.7 Deploy to PRODUCTION Environment

```bash
swa deploy ./build --deployment-token daa592b2b9965dad8ca7518a54c530d5c5546568e344bac1b478cd29f0aef98c07-40a63ab7-8780-489e-b23f-36871e264a8100326040eca32d03 --env production
```

---

## 2. VMSS API Deployment (vmss_api - IIS Deployment)

### 2.1 Install .NET 8 Hosting Bundle

### Download: 
https://dotnet.microsoft.com/en-us/download/dotnet/8.0

### Install:
1. ASP.NET Core Runtime
2. IIS Integration Module

### 2.2 Verify IIS Module

```powershell
Get-WebGlobalModule | findstr AspNetCore
```

### Expected:

```
AspNetCoreModuleV2
```

### 2.3 Build API Project

```powershell
cd vmss_api\LaptopStoreApi

dotnet clean
dotnet restore
dotnet build
```

### 2.4 Publish API

```powershell
Remove-Item -Recurse -Force .\publish\

dotnet publish -c Release -o ./publish
```

### 2.5 Create Deployment Folder (VM)

```powershell
mkdir C:\apps\LaptopStoreApi
```

### 2.6 Copy Publish Folder to VMSS VM

### Copy:

```
LaptopStoreApi/publish → C:\apps\LaptopStoreApi
```

### 2.7 IIS Configuration

### Create Application Pool

1. Name: LaptopStoreApiPool
2. .NET CLR: No Managed Code
3. Pipeline: Integrated

### Set Website Path

### IIS Manager →

1. Default Web Site → Advanced Settings
2. Physical Path:
```
C:\apps\LaptopStoreApi
```

### Attach App Pool
1. Assign: LaptopStoreApiPool


### 2.8 API Endpoint Structure

```
http://<server>/api/order
```

### 2.9 API Verification

```bash
curl https://prd-eda-api.hbcdev.co.in/health
curl https://dr-eda-api.hbcdev.co.in/health
```
Expected:

```
Healthy
```
### Swagger:

```
https://prd-eda-api.hbcdev.co.in/swagger
https://dr-eda-api.hbcdev.co.in/swagger
```

### 2.10 Test API POST Request

```powershell
Invoke-RestMethod `
-Uri "http://prd-eda-api.hbcdev.co.in/api/order" `
-Method POST `
-ContentType "application/json" `
-Body '{
  "customerName":"George",
  "customerAddress":"Chennai",
  "email":"john@test.com",
  "mobileNo":"9999999999",
  "laptopModel":"Dell",
  "ram":"16GB",
  "cpu":"i7",
  "quantity":1
}'
```

### 2.11 Identity-Based Queue Test (Optional)

```
az login --identity
```

Then test API:

```
POST /api/order
```

If RBAC works:

```
Message should land in Storage Queue
```

---

## 3. Database Setup (SQL VM)

### 3.1 Create Orders Table

```SQL 
CREATE TABLE Orders (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100),
    CustomerAddress NVARCHAR(200),
    Email NVARCHAR(100),
    MobileNo NVARCHAR(20),
    LaptopModel NVARCHAR(100),
    RAM NVARCHAR(50),
    CPU NVARCHAR(50),
    Quantity INT,
    CreatedDate DATETIME DEFAULT GETDATE()
);
```

### 3.2 Verify Data

```SQL
SELECT TOP 100 *
FROM Orders
ORDER BY Id DESC;
```

```SQL
SELECT * FROM Orders;
```

### 3.3 Cleanup (Optional)

```SQL
DELETE FROM Orders;
```

---

## 4. Azure Function App Deployment (function_app)

### 4.1 Build Function App

```Powershell
Remove-Item -Recurse -Force .\publish\

dotnet clean
dotnet restore
dotnet build

dotnet publish -c Release -o ./publish
```

### 4.2 Create ZIP Package

```Powershell
cd .\publish
Compress-Archive -Path * -DestinationPath functionapp.zip
```

### 4.3 Deploy to Azure Function App

```Powershell
az functionapp deployment source config-zip --resource-group prd-rg --name prd-eda-funcapp --src functionapp.zip
az functionapp deployment source config-zip --resource-group dr-rg --name dr-eda-funcapp --src functionapp.zip
```

---

## 5. End-to-End Local Testing Flow

### 5.1 Frontend Test

```bash
cd frontend
npm install
npm start
```

OR:

```bash
npx serve -s build
```

### 5.2 API Local Test

```bash
dotnet run
```

Test:
```
http://localhost:5000/api/order
```

### 5.3 Full Flow Test

1. React UI → Submit Order
2. VMSS API receives request
3. Function App processes event
4. Queue stores message
5. SQL stores order
6. Logic App sends email

---

## 6. Production Verification

### 6.1 API Health
```
curl https://prd-eda-api.hbcdev.co.in/health
```

### 6.2 Swagger
```
https://prd-eda-api.hbcdev.co.in/swagger
```

### 6.3 Static Web App

### Production
```
https://prd-eda.hbcdev.co.in/
```

### DR
```
https://dr-eda.hbcdev.co.in/
```

### 6.4 Traffic Manager
```
https://eda.hbcdev.co.in/
```

---

## 7. Final Deployment Flow Summary

```
Static Web App (Frontend (React))
        ↓
Traffic Manager
        ↓
VMSS API (IIS + .NET 8)
        ↓
Storage Queue
        ↓
Function App (.NET 8) → Logic App (Email)
        ↓
SQL VM
```
---




