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

---

## Simplified Infrastructure Architecture

<img width="2250" height="1642" alt="image" src="https://github.com/user-attachments/assets/79f481a3-63a2-4145-a4d6-e0c38d3fffcb" />

---

## DR Failover Workflow Architecture

<img width="1036" height="672" alt="image" src="https://github.com/user-attachments/assets/b120b0eb-bd0a-4b72-9246-be44ae993fc0" />

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
- JavaScript
- Axios

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


