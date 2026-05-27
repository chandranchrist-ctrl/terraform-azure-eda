# Application Deployment + Validation Runbook (EDA Architecture)

# =========================================
# 1. STATIC WEB APP (FRONTEND DEPLOYMENT)
# =========================================

## CLEAN BUILD
Remove-Item -Recurse -Force .\build\

---

## BUILD FRONTEND
cd frontend
npm install
npm run build

---

## LOCAL TESTING (REACT)

Start dev server:
npm start

OR production preview:
npx serve -s build

Install serve if needed:
npm install -g serve

---

## AZURE SWA CLI INSTALL
npm install -g @azure/static-web-apps-cli

---

## LOCAL SWA RUN (OPTIONAL)
swa start ./build

---

## DEPLOY TO PREVIEW
swa deploy ./build --deployment-token 8b06c4b78ad6aef9aa8cd7f1b40c974a368697c8f3df71c6deda4023b149bd9507-e3c3fb7f-9a0b-4dc1-80ba-2e2ced283c6a00016020fff28c00

---

## DEPLOY TO PRODUCTION
swa deploy ./build --deployment-token daa592b2b9965dad8ca7518a54c530d5c5546568e344bac1b478cd29f0aef98c07-40a63ab7-8780-489e-b23f-36871e264a8100326040eca32d03 --env production

---

# =========================================
# 2. VMSS API DEPLOYMENT (IIS + .NET 8)
# =========================================

## INSTALL HOSTING BUNDLE
Download:
https://dotnet.microsoft.com/en-us/download/dotnet/8.0

Install:
- ASP.NET Core Hosting Bundle
- IIS Integration Module

---

## VERIFY IIS MODULE
Get-WebGlobalModule | findstr AspNetCore

Expected:
AspNetCoreModuleV2

---

## BUILD API
cd vmss_api\LaptopStoreApi

dotnet clean
dotnet restore
dotnet build

---

## PUBLISH API
Remove-Item -Recurse -Force .\publish\

dotnet publish -c Release -o ./publish

---

## COPY TO VMSS SERVER
Create folder:
mkdir C:\apps\LaptopStoreApi

Copy:
publish/* → C:\apps\LaptopStoreApi

---

## IIS CONFIGURATION

Create App Pool:
- Name: LaptopStoreApiPool
- .NET CLR: No Managed Code
- Pipeline: Integrated

---

Set Website Path:
Default Web Site → Advanced Settings
Physical Path:
C:\apps\LaptopStoreApi

Assign App Pool:
LaptopStoreApiPool

---

## API ENDPOINT
http://<server>/api/order

---

## API HEALTH CHECK
curl https://prd-eda-api.hbcdev.co.in/health
curl https://dr-eda-api.hbcdev.co.in/health

Expected:
Healthy

---

## SWAGGER CHECK
https://prd-eda-api.hbcdev.co.in/swagger
https://dr-eda-api.hbcdev.co.in/swagger

---

## API TEST (POST)

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

---

## VMSS IDENTITY TEST
az login --identity

Test:
POST /api/order

---

# =========================================
# 3. SQL VM SETUP
# =========================================

## CREATE TABLE

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

---

## VERIFY DATA
SELECT TOP 100 * FROM Orders ORDER BY Id DESC;
SELECT * FROM Orders;

---

## CLEAN TABLE
DELETE FROM Orders;

---

# =========================================
# 4. AZURE FUNCTION APP DEPLOYMENT
# =========================================

## BUILD FUNCTION APP
Remove-Item -Recurse -Force .\publish\

dotnet clean
dotnet restore
dotnet build

dotnet publish -c Release -o ./publish

---

## CREATE ZIP
cd publish
Compress-Archive -Path * -DestinationPath functionapp.zip

---

## DEPLOY FUNCTION APP
az functionapp deployment source config-zip `
--resource-group dr-rg `
--name dr-eda-funcapp `
--src functionapp.zip

---

# =========================================
# 5. LOCAL END-TO-END TESTING
# =========================================

## FRONTEND
cd frontend
npm install
npm start

OR:
npx serve -s build

---

## API LOCAL
dotnet run

Test:
http://localhost:5000/api/order

---

## FULL FLOW
React UI → VMSS API → Function App → Queue → SQL → Logic App

---

# =========================================
# 6. PRODUCTION VERIFICATION
# =========================================

## API HEALTH
curl https://prd-eda-api.hbcdev.co.in/health

---

## SWAGGER
https://prd-eda-api.hbcdev.co.in/swagger

---

## STATIC WEB APP

UAT:
https://uat-eda.hbcdev.co.in/

DR:
https://dr-eda.hbcdev.co.in/

PROD:
https://prd-eda.hbcdev.co.in/

---

## TRAFFIC MANAGER
https://eda.hbcdev.co.in/

---

## VMSS API
https://prd-eda-api.hbcdev.co.in
https://dr-eda-api.hbcdev.co.in

---

# =========================================
# 7. END-TO-END FLOW
# =========================================

Frontend (React)
    ↓
Static Web App
    ↓
Traffic Manager
    ↓
VMSS API (IIS + .NET)
    ↓
Azure Function App
    ↓
Storage Queue
    ↓
SQL VM
    ↓
Logic App (Email Notification)

---
