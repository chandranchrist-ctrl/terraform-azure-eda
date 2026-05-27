# 🚀 Azure Event-Driven Architecture (EDA) with Multi-Region Disaster Recovery using Terraform

## 📖 Project Overview

This project demonstrates a production-style Azure Event-Driven Architecture (EDA) platform deployed using Terraform Infrastructure as Code (IaC).

The solution includes:
- Multi-region Disaster Recovery (DR)
- Azure Traffic Manager global routing
- Queue-based asynchronous processing
- VM Scale Set (VMSS) API hosting
- Azure Function App background processing
- Logic App notification workflows
- Azure Static Web Apps frontend
- Secure private networking architecture
- Automated DNS integration with GoDaddy API

The platform is designed to simulate a scalable enterprise-grade cloud architecture with automated failover and disaster recovery capabilities.

---

# 🏗️ Architecture Diagrams

## High-Level Application Architecture

<img width="1934" height="742" alt="image" src="https://github.com/user-attachments/assets/849a12ec-f8d5-4b87-a2f7-06bff542b384" />

Explanation:

1. This diagram shows the overall flow of the application from user to backend systems. Requests from the Static Web App go through Traffic Manager and are routed to the appropriate environment. 
2. The VMSS API, Function App, Queue, and SQL work together to process and store data in an event-driven flow, with Logic App handling external notifications.

---
## Multi-Region Azure Infrastructure Architecture with Disaster Recovery

<img width="2250" height="1642" alt="image" src="https://github.com/user-attachments/assets/79f481a3-63a2-4145-a4d6-e0c38d3fffcb" />

Explanation: 
1. This diagram represents the deployment of the application across Primary and DR regions.
2. Traffic Manager distributes traffic between regions, ensuring high availability.
3. Each region contains identical services (SWA, VMSS, Function App, SQL, Storage) to support seamless failover in case of failure.

---

## DR Failover Workflow Architecture

<img width="1036" height="672" alt="image" src="https://github.com/user-attachments/assets/b120b0eb-bd0a-4b72-9246-be44ae993fc0" />

Explanation: 

1. This diagram explains the failover process when the primary region becomes unavailable.
2. Traffic Manager detects failure and automatically redirects traffic to the DR region. The DR environment takes over all services to ensure continuous application availability with minimal downtime.

---

# ✨ Key Features

- 🌍 Multi-region Disaster Recovery (DR)
- 🔀 Azure Traffic Manager failover routing
- ⚡ Event-Driven Architecture (EDA)
- 📦 Queue-based asynchronous processing
- 🖥️ Windows VMSS API hosting
- ⚙️ Azure Function queue-trigger processing
- 📧 Logic App email notifications
- 🔒 Private networking and Private DNS
- 🔑 Azure Key Vault integration
- 🛡️ Bastion-based administrative access
- 🧱 Modular Terraform architecture
- 🌐 Automated GoDaddy DNS management

---

# 💻 Application Components

## 🌐 Static Web App (React)

Frontend application hosted using Azure Static Web Apps.

### Responsibilities
- User order submission portal
- API integration
- Global access through Traffic Manager

### Technology Stack
- React

---

## 🖥️ VMSS API Application (.NET + IIS)

Backend API application hosted on Windows VM Scale Sets with IIS.

### Responsibilities
- Receive order requests
- Validate payloads
- Publish messages to Azure Queue Storage

### Technology Stack
- ASP.NET Web API
- IIS
- Azure Queue SDK

---

## ⚙️ Azure Function App (.NET)

Queue-triggered serverless processing layer.

### Responsibilities
- Process queue messages
- Insert records into SQL Server
- Invoke Logic App notification workflow

### Technology Stack
- .NET Isolated Worker
- Azure Functions
- Azure Queue Trigger

---

# ☁️ Infrastructure Components

| Component | Purpose |
|---|---|
| Azure VMSS | API hosting and autoscaling |
| Azure Function App | Queue-based background processing |
| Azure Logic App | Email notification workflow |
| Azure Static Web App | Frontend application hosting |
| Azure Traffic Manager | Global routing and DR failover |
| Azure Storage Account | Queue and application storage |
| Azure SQL VM | Order database |
| Azure Key Vault | Secrets and SSL certificate management |

---

# 📂 Repository Structure

```text
terraform-azure-eda
│
├── architecture
│
├── docs
│
├── envs
│   └── staging
│       ├── certs
│       ├── region-a
│       ├── region-b
│       └── ssh
│
├── modules
│   ├── az-ad-access
│   ├── az-appserviceplan
│   ├── az-bastion
│   ├── az-compute
│   │   ├── vmss
│   │   └── sql_in_vm
│   ├── az-dns
│   ├── az-function-app
│   ├── az-loadbalancer
│   ├── az-logicapp
│   ├── az-logicapp-api-connection
│   ├── az-nat-gateway
│   ├── az-network
│   ├── az-rg
│   ├── az-static-web-app
│   ├── az-storage
│   ├── az-trafficmanager
│   └── az-vnet-peering
│
├── scripts
│   ├── dr_failover.ps1
│   ├── dr_rollback.ps1
│   └── sql-server-setup.ps1
│
└── workload
    ├── db
    │   └── Query
    ├── function_app (.NET)
    ├── static_webapp (React)
    └── vmss_api (.NET)
```
---

# 🌍 Regional Deployment Model

| Component | Primary Region | DR Region |
|---|---|---|
| Static Web App | East Asia | West Europe |
| Backend Infrastructure | Central India | South India |
| Traffic Manager | Global | Global |
| DNS Routing | GoDaddy | GoDaddy |

---

# ⚡ Event-Driven Workflow

1. User submits an order through the React frontend.
2. Request reaches the VMSS API through Azure Load Balancer.
3. API validates the request and publishes a queue message.
4. Azure Function App processes the queue message.
5. Function App inserts the order into SQL Server.
6. Function App invokes Logic App HTTP trigger.
7. Logic App sends email notifications using Gmail Connector.

---

# 🔄 Disaster Recovery Workflow

The platform uses Azure Traffic Manager with active-passive failover architecture.

### DR Process

1. Primary Traffic Manager endpoint is disabled.
2. Custom domain (`eda.example.co.in`) is removed from the Primary Static Web App.
3. DNS for `eda.example.co.in` (the custom domain mapped to Azure Traffic Manager) is temporarily pointed to the DR Static Web App default hostname for Host Header validation.
4. Custom domain is attached to the DR Static Web App.
5. DNS for `eda.example.co.in` is restored back to the Azure Traffic Manager endpoint.
6. Traffic Manager routes user traffic to the DR environment.

### Important Note

Azure Static Web Apps validate incoming requests using the Host Header / custom domain binding.  
Because users access the application through the Traffic Manager custom domain (`eda.example.co.in`), the domain must be temporarily moved from the Traffic Manager endpoint to the DR Static Web App hostname during failover validation and binding operations.

---

# 🔐 Security Architecture

- Azure Key Vault for secrets and SSL certificates
- Managed Identity authentication
- Private DNS Zones
- Private Endpoints
- NSG-based subnet isolation
- Bastion-based administrative access
- HTTPS-only application access
- RBAC-based permission management
- VNet-integrated Function Apps

---

# 🧱 Terraform Module Structure

The infrastructure is deployed using reusable Terraform modules.

### Major Modules
- az-network
- az-storage
- az-function-app
- az-loadbalancer
- az-static-web-app
- az-trafficmanager
- az-logicapp
- az-keyvault
- az-bastion
- az-vnet-peering

The modular structure improves:
- Reusability
- Maintainability
- Environment separation
- DR scalability

---

# 🚀 Infrastructure Deployment Flow

Infrastructure deployment follows this sequence:

1. Resource Groups
2. Networking and VNets
3. DNS and Private DNS Zones
4. Key Vault
5. Storage Accounts
6. SQL Server VM
7. VM Scale Sets
8. Function App
9. Logic App
10. Static Web Apps
11. Traffic Manager
12. DR onboarding

---

# 🔮 Future Improvements

- CI/CD pipeline integration
- Azure Front Door with WAF
- AKS-based microservices migration
- Active-Active DR architecture
- Redis caching layer
- Centralized monitoring dashboards
- Automated DR testing workflows

---

# ⚠️ Known Limitations / Considerations

- Azure Static Web Apps require custom-domain rebinding during DR failover.
- DNS propagation timing may affect failover duration.
- Current DR model is Active-Passive.
- GoDaddy API availability is required for automated DNS updates.
- SQL replication is simulated using environment separation.

---

# ✅ Conclusion

This project demonstrates a scalable and secure Azure Event-Driven Architecture platform with enterprise-style Disaster Recovery implementation using Terraform.

The solution combines:
- Infrastructure as Code
- Multi-region architecture
- Queue-driven processing
- Automated failover workflows
- Secure networking design
- Cloud-native Azure services

to simulate a production-ready cloud platform deployment model.

---

## Important Notes

1. This project is intended for learning, experimentation, and architectural demonstration purposes.
2. Some Azure resources used in this implementation may incur cloud usage costs when deployed.
3. Certain configurations may require subscription-level permissions, elevated RBAC access, or Azure service quotas.
4. Some SKU selections, regional deployments, feature enablement, and scaling configurations were intentionally constrained based on lab environment limitations and cost optimization considerations.
5. While certain deployment choices were optimized for lab constraints, the Terraform codebase remains modular, extensible, and aligned with enterprise implementation patterns.
