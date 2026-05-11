terraform {
  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.67.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Local values for environment-specific naming
locals {
  env      = "ci-uat"
  workload = "eda"
}

# Reusable module to create Resource Group
module "rg" {
  source = "../../../modules/az-rg"

  env = local.env

  # Input Variables
  resource_group_name     = "${local.env}-rg"
  resource_group_location = "centralindia"

  tags = {
    environment = "uat"
    # project     = "webapp"
    # owner       = "devops"
  }
}


# Network module for hub-spoke setup (VNet, Subnet, NSG, NSG Rules)
module "virtual_network" {
  source = "../../../modules/az-network"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Controls internet access from subnet: true = allows default outbound internet, false = blocks unless explicitly configured (e.g., NAT/Firewall)
  default_outbound_access_enabled = false

  jhost_allowed_sources = var.allowed_ips

  # VNet CIDR
  # {VNet key = hub\spoke} must match the corresponding key in subnet_address_space to map subnets to the correct VNet
  vnet_address_space = {
    hub_vnet   = ["10.0.0.0/16"]
    app_svnet  = ["172.16.0.0/16"]
    data_svnet = ["192.168.0.0/16"]
  }

  # Subnet CIDR
  # {Subnet key = AzureFirewallSubnet\app} must align with the VNet key to ensure subnets are created within the correct VNet
  subnet_address_space = {
    hub_vnet = {
      AzureBastionSubnet = {
        cidr = ["10.0.1.0/26"]
        tags = { type = "infra" }
      }
      snet_mgmt = {
        cidr = ["10.0.1.64/28"]
        tags = { type = "workload" }
      }
    }

    app_svnet = {
      snet_vmss = {
        cidr = ["172.16.1.0/24"]
        tags = { type = "workload" }
      }
      snet_lb = {
        cidr = ["172.16.2.0/24"]
        tags = { type = "infra" }
      }
      snet_functions = {
        cidr = ["172.16.3.0/24"]
        tags = { type = "infra" }

        delegation = {
          name = "delegation"

          service_delegation = {
            name = "Microsoft.Web/serverFarms"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/action"
            ]
          }
        }
      }
      snet_app_pe = {
        cidr = ["172.16.4.0/24"]
        tags = { type = "infra" }
      }
    }

    data_svnet = {
      snet_db = {
        cidr = ["192.168.1.0/24"]
        tags = { type = "workload" }
      }
      snet_data_pe = {
        cidr = ["192.168.2.0/24"]
        tags = { type = "infra" }
      }
    }
  }
}


# Network - VNet Peering
module "vnet_peering" {
  source = "../../../modules/az-vnet-peering"


  peerings = {
    hub_to_app = {
      name                    = "${local.env}-hub-to-app"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub_vnet"].name
      remote_vnet_id          = module.virtual_network.vnets["app_svnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    app_to_hub = {
      name                    = "${local.env}-app-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["app_svnet"].name
      remote_vnet_id          = module.virtual_network.vnets["hub_vnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    hub_to_data = {
      name                    = "${local.env}-hub-to-data"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub_vnet"].name
      remote_vnet_id          = module.virtual_network.vnets["data_svnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    data_to_hub = {
      name                    = "${local.env}-data-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["data_svnet"].name
      remote_vnet_id          = module.virtual_network.vnets["hub_vnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    app_to_data = {
      name                    = "${local.env}-app-to-data"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["app_svnet"].name
      remote_vnet_id          = module.virtual_network.vnets["data_svnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    data_to_app = {
      name                    = "${local.env}-data-to-app"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["data_svnet"].name
      remote_vnet_id          = module.virtual_network.vnets["app_svnet"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }
  depends_on = [module.virtual_network]
}

# Network - Private DNS
module "private_dns" {
  source = "../../../modules/az-dns/private"

  resource_group_name = module.rg.resource_group_name

  /* list of private DNS zones to create */
  zones = [
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.queue.core.windows.net", /* Private DNS zone for Azure Storage (Queue) private endpoints */
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net",
    "internal.hbcdev.co.in"
  ]

  /* VNets to link with DNS zones for name resolution */
  vnet_ids = [
    module.virtual_network.vnets["hub_vnet"].id,
    module.virtual_network.vnets["app_svnet"].id,
    module.virtual_network.vnets["data_svnet"].id
  ]

  depends_on = [
    module.virtual_network
  ]
}

# Security - Key Vault
module "key_vault" {
  source = "../../../modules/az-keyvault"

  name = var.key_vault_name /* "${local.env}-${local.workload}-kv-17" = Key Vault names must be globally unique across Azure. */

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  owner_group_id  = module.access.group_ids["kv_admins"]
  devops_group_id = module.access.group_ids["kv_devops"]

  /* false = uses access policies, true = uses RBAC */
  rbac_authorization_enabled = true

  /* true = creates access for current user, false = no access policy */
  create_access_policy_me = false

  /* standard = basic features, premium = supports HSM-backed keys */
  sku_name = "premium" # Standard or Premium

  soft_delete_retention_days = 7 /* days to retain deleted items (7–90) */
  purge_protection_enabled   = false /* true = prevents permanent deletion, false = allows purge */

  enabled_for_deployment          = true /* true = allows VM deployment access */
  enabled_for_template_deployment = true /* true = allows ARM template access */

  enable_private_endpoint = true
  private_subnet_id       = module.virtual_network.subnet_lookup["snet_mgmt"]
  private_dns_zone_id     = module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]

  public_network_access_enabled = true /* true = allows public access, false = private only */

  network_acls_default_action = "Deny" /* Deny = block all except allowed, Allow = open access */
  allowed_ip_ranges           = var.allowed_ips # ["49.37.211.93/32"] /* allowed public IPs */

  /*   For subnet restrictions, ensure the subnets exist and are correctly referenced.
  service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module. */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["snet_mgmt"],
    module.virtual_network.subnet_lookup["snet_vmss"],
    module.virtual_network.subnet_lookup["snet_functions"],
    module.virtual_network.subnet_lookup["snet_db"]
  ]

  # Security - SSH Key
  /* stores SSH public key as secret */
  ssh_secret_name = "linux-ssh-public-key"
  ssh_public_key  = file("${path.module}/../ssh/id_rsa.pub")

  # Security - Secrets
  /* key-value secrets stored in Key Vault */
  secrets = {
    localadmin-credentials = jsonencode({
      admin-username = "HBAdmin",
      admin-password = "Qwerty123!",
    })

    mssql-credentials = jsonencode({
      username = "sqladmin"
      password = "SQLP@ssword!23!"
    })

    /* Stores GoDaddy API credentials (API Key and Secret) as a JSON-encoded string, typically used for programmatic DNS management or domain automation */
    godaddy-apikey = jsonencode({
      Key    = "hkHptCfQoPVe_S64u3fVz88NYAZwGPuE9ir"
      Secret = "QLsAdAfb4pLq4VsVMQ2gFT"
    })
  }

  # Security - Certificates
  /* imports certificates from PFX */
  certificates = [
    {
      name     = "wildcard-cert"
      pfx_path = "./../certs/certificate.pfx"
      password = "Y12345Z"
    }
  ]

  # Monitoring - Diagnostics
  audit_storage_account_name = module.diag_storage_account.storage_account_name
  audit_storage_account_rg   = module.rg.resource_group_name

  # depends_on ensures storage account is created before enabling diagnostics
  depends_on = [
    module.diag_storage_account,
    module.private_dns,
    module.virtual_network,
    module.access
  ]
}


# Storage - diagnostics
module "diag_storage_account" {
  source = "../../../modules/az-storage"

  storage_account_name = var.diag_storage_account_name

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  account_kind          = "StorageV2" /* StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage */
  account_tier          = "Standard" /* Standard or Premium */
  replication_type      = "LRS" /* LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS */
  dns_endpoint_type     = "Standard" /* Standard or MicrosoftEndpointsOnly */
  public_network_access = true /* disable public endpoint for enhanced security; access will be via private endpoint or service endpoints from allowed subnets */

  # retention / governance
  blob_versioning_enabled         = false /* enable blob versioning for data protection and recovery */
  blob_delete_retention_days      = 1 /* enable soft delete for blobs with a retention period of 1 day; adjust as needed */
  container_delete_retention_days = 1 /* enable soft delete for containers with a retention period of 1 day; adjust as needed */

  # network rules
  /* Only allow private network access (recommended) */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["snet_vmss"],
    module.virtual_network.subnet_lookup["snet_db"],
    module.virtual_network.subnet_lookup["snet_mgmt"]
  ]

  allowed_ip_rules = var.allowed_ips_plain # ["49.37.211.93"] /* allows access from specific public IPs */

  # Lifecycle Enabled
  /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
  lifecycle_rules = [
    {
      name   = "diag-cleanup"
      prefix = ["bootdiagnostics", "insights-logs"]
      days   = 1
    }
  ]

  depends_on = [
    module.virtual_network
  ]
}

# Storage - mysql
module "mysql_storage_account" {
  source = "../../../modules/az-storage"

  storage_account_name = var.mysql_storage_account_name

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name

  tags = merge(module.rg.tags, {
    purpose = "mysql-logging"
  })

  account_kind          = "StorageV2"
  account_tier          = "Standard"
  replication_type      = "LRS"
  dns_endpoint_type     = "Standard"
  public_network_access = true

  allowed_ip_rules = var.allowed_ips_plain #  ["49.37.211.93"]

  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["snet_db"]
  ]

  blob_versioning_enabled = false

  blob_delete_retention_days      = 1
  container_delete_retention_days = 1

  /* List of storage containers to create inside the storage account (each item becomes one container) */
  containers = [
    "mysql-auditlogs",
    "mysql-va-logs"
  ]

  # Lifecycle Enabled (multi-rule)
  lifecycle_rules = [
    {
      name   = "audit-retention"
      prefix = ["mysql-auditlogs"]
      days   = 1
    },
    {
      name   = "va-retention"
      prefix = ["mysql-va-logs"]
      days   = 1
    }
  ]

  depends_on = [
    module.virtual_network
  ]

}

# Storage - Storage Account{for diagnostics}
/* Creates a Storage Account to securely store application data such as logs, backups, and other artifacts with controlled access, retention, and networking rules */
# module "appservice_storage_account" {
#   source = "../../modules/az-storage"

#   storage_account_name = var.appservice_storage_account_name

#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   account_kind          = "StorageV2" /* StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage */
#   account_tier          = "Standard" /* Standard or Premium */
#   replication_type      = "LRS" /* LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS */
#   dns_endpoint_type     = "Standard" /* Standard or MicrosoftEndpointsOnly */
#   public_network_access = true /* disable public endpoint for enhanced security; access will be via private endpoint or service endpoints from allowed subnets */

#   # retention / governance
#   blob_versioning_enabled         = false /* enable blob versioning for data protection and recovery */
#   blob_delete_retention_days      = 1 /* enable soft delete for blobs with a retention period of 1 day; adjust as needed */
#   container_delete_retention_days = 1 /* enable soft delete for containers with a retention period of 1 day; adjust as needed */

#   # network rules
#   /* Only allow private network access (recommended) */
#   allowed_subnet_ids = [
#     module.virtual_network.subnet_lookup["app"]
#   ]

#   # allowed_ip_rules = var.allowed_ips_plain # ["49.37.211.93"] /* allows access from specific public IPs */

#   allowed_ip_rules = concat(
#     var.allowed_ips_plain,
#     module.app_service.outbound_ips
#   )

#   /* List of storage containers to create inside the storage account (each item becomes one container) */
#   /* Defines storage containers for segregating data: app-logs (application logs), http-logs (web/server access logs), and backups (data/application backups for recovery) */
#   containers = [
#     "app-logs",
#     "http-logs",
#     "backups"
#   ]

#   enable_sas = true

#   # Lifecycle Enabled
#   /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
#   lifecycle_rules = [
#     {
#       name   = "app-logs-retention"
#       prefix = ["app-logs/"]
#       days   = 1
#     },
#     {
#       name   = "http-logs-retention"
#       prefix = ["http-logs/"]
#       days   = 1
#     },
#     {
#       name   = "backup-retention"
#       prefix = ["backups/"]
#       days   = 1
#     }
#   ]

#   depends_on = [
#     module.virtual_network,
#   ]
# }

# # Observability
# module "log_analytics" {
#   source = "../../modules/az-log-analytics"

#   # Basic Identity
#   env      = local.env
#   workload = local.workload

#   create_law = true

#   name                = "${local.env}-${local.workload}-law" # -> UAT; Workspace for per environment.
#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   # ACCESS (AAD GROUPS)
#   /* Assigns Azure AD groups to the Log Analytics Workspace, granting owners full management access and DevOps team read/monitoring access */
#   owner_group_id  = module.access.group_ids["law_admins"]
#   devops_group_id = module.access.group_ids["law_devops"]

#   sku               = "PerGB2018"
#   retention_in_days = 30
#   daily_quota_gb    = 1

#   # Explicit configs (so you KNOW what’s enabled)
#   allow_resource_only_permissions         = true
#   local_authentication_enabled            = true
#   internet_query_enabled                  = true
#   immediate_data_purge_on_30_days_enabled = false
# }

# Network Security - Azure Bastion
# module "bastion" {
#   source = "../../modules/az-bastion"

#   enable_bastion = true

#   env = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   subnet_id = module.virtual_network.subnet_lookup["AzureBastionSubnet"] /* dedicated Bastion subnet */

#   sku = "Standard" /* Basic or Standard (Standard = more features) */

#   tunneling_enabled  = true /* true = allows native client (SSH/RDP) via Bastion */
#   ip_connect_enabled = true /* true = connect using private IP */
#   copy_paste_enabled = true /* true = enable clipboard */
#   file_copy_enabled  = true /* true = allow file transfer */

#   zones = null /* null = no zone redundancy, ["1","2","3"] = zone redundant */

#   kerberos_enabled = false /* true = enable Kerberos auth, false = disabled */

#   depends_on = [
#     module.virtual_network
#   ]
# }

# Linux JumpHost VM Deployment Module
/* Creates one or more Linux VMs with networking, disks, identity, and optional integrations (LB, ASG, Backup, Diagnostics) */
# module "jumpbox_linux_vm" {
#   source = "../../modules/az-compute/linux_vm_jh"

#   env      = local.env
#   workload = local.workload

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   vm_name  = "${local.env}-jumpbox-linux"
#   vm_count = 1

#   vm_size   = "Standard_B2s_v2"
#   image_sku = "18.04-LTS"

#   subnet_id = module.virtual_network.subnet_lookup["jumpbox"]

#   private_ip_allocation = "Dynamic"

#   os_disk_storage_type = "Standard_LRS"
#   os_disk_size_gb      = 127

#   enable_public_ip = false /* true  → VM gets public IP (direct internet access) */

#   enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */

#   availability_set_name = "biztalk-avset"

#   zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

#   enable_boot_diagnostics               = false
#   boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
#   boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

#   /*Fetches admin credentials from Key Vault instead of hardcoding
#   Helps secure VM username/password */
#   key_vault_id                       = module.key_vault.key_vault_id # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password
#   localadmin_credentials_secret_name = "localadmin-credentials"

#   # Authentication method
#   /* true  → only SSH login (recommended for production)
#    false → password + SSH allowed */
#   disable_password_authentication = false

#   ssh_public_key_secret_name = "linux-ssh-public-key" /* SSH public key stored in Key Vault */

#   enable_asg = false

#   # enable_lb = false                                         /* true  → attaches VM NICs to Load Balancer backend pool */

#   # Scenario 1: Existing LB
#   # lb_name              = "existing-lb-name"
#   # lb_backend_pool_name = "backend-pool-name"

#   # Scenario 2: New LB scenario (created in same Terraform)
#   # lb_backend_pool_id = module.loadbalancer.backend_pool_id        # null

#   # Data disks (optional)
#   /*
#   data_disks = [
#     {
#       # size_gb = 128
#       # lun     = 0
#       # caching = "ReadWrite"
#       # storage_type = "Standard_LRS"
#     }
#   ] 
#   */

#   # Backup configuration
#   enable_backup = false /* true  → enables VM backup using Recovery Services Vault */

#   # Recovery Serivce Vault Configuration
#   recovery_services_vault_name = "existing-rsv"
#   backup_policy_vm             = "existing-policy"

#   # Ensure dependencies are created before VM
#   depends_on = [
#     module.key_vault,
#     module.diag_storage_account,
#     module.virtual_network,
#     module.access
#   ]
# }

# Platform - MSSQL 
# module "mssql" {
#   source = "../../modules/az-compute/rds/mssql"

#   env      = local.env
#   workload = local.workload

#   # Basic Identity
#   server_name   = "${local.env}-${local.workload}-sql1"
#   database_name = "${local.env}_${local.workload}_db1"

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Server Config
#   server_version = "12.0"

#   /* Pricing tier
#      Examples:
#      Basic → dev/test
#      S0/S1 → small workloads
#      GP_* → General Purpose (recommended)
#      BC_* → Business Critical (high IO + HA) */
#   sku_name = "Basic"

#   max_size_gb = 2

#   # Collation for sorting/comparison
#   collation = "SQL_Latin1_General_CP1_CI_AS"

#   # Zone redundancy (multi-zone HA)
#   zone_redundant = false

#   # Read scale (read-only replicas)
#   read_scale = false

#   # Storage type
#   # Local → cheaper
#   # Geo → geo-redundant backup
#   storage_account_type = "Local"

#   storage_account_id = module.mssql_storage_account.storage_account_id

#   # Authentication (from Key Vault)
#   key_vault_id    = module.key_vault.key_vault_id
#   sql_secret_name = "mssql-credentials"

#   enable_aad_admin        = false
#   azuread_admin_username  = "AzureAD Admin"
#   azuread_admin_object_id = null


#   # Network Mode (UAT/PROD toggle)
#   enable_public_access    = true # PROD → false (private only), UAT → can be true if needed
#   enable_private_endpoint = true
#   private_subnet_id       = module.virtual_network.subnet_lookup["private_endpoint"]
#   private_dns_zone_id     = module.private_dns.zone_ids["privatelink.database.windows.net"]

#   # Service Endpoint
#   enable_service_endpoint_mssql = false
#   app_subnet_id                 = module.virtual_network.subnet_lookup["db"]

#   allowed_ips = var.allowed_ips_plain # ["49.37.211.93"] # only used if public enabled

#   # TDE (Encryption) /* false = system managed key */
#   enable_tde       = false
#   use_cmk_tde      = false
#   key_vault_key_id = null
#   # key_vault_key_id = module.key_vault.sql_tde_key_id


#   # Auditing
#   enable_auditing        = false
#   audit_storage_endpoint = module.mssql_storage_account.primary_blob_endpoint
#   audit_retention_days   = 1


#   # Security Alerts
#   enable_security_alerts = false
#   alert_retention_days   = 1
#   alerts_state           = "Enabled"

#   # Email Accounts
#   email_account_admins = false
#   email_addresses = [
#     "dba@company.com",
#     "cloudops@company.com",
#     "security@company.com"
#   ]

#   # Vulnerability Assessment
#   enable_va = false
#   va_state  = false # or "Disabled"

#   va_storage_container = module.mssql_storage_account.container_urls["sql-va-logs"]
#   va_storage_key       = module.mssql_storage_account.primary_access_key


#   # Backup / LTR
#   short_term_retention_days = 7

#   enable_long_term_retention = false

#   ltr_weekly_retention  = "P4W"
#   ltr_monthly_retention = "P12M"
#   ltr_yearly_retention  = "P3Y"
#   ltr_week_of_year      = 1


#   # Optional Features
#   enable_outbound_firewall = false

#   # Dependencies
#   depends_on = [
#     module.key_vault,
#     module.virtual_network,
#     module.mssql_storage_account,
#     module.private_dns
#   ]
# }

# # Platform - ACR
# module "acr" {
#   source = "../../modules/az-acr"

#   # 1. BASIC INFO
#   env      = local.env
#   workload = local.workload

#   acr_name            = "${local.env}${local.workload}acr01"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # 2. ACCESS (AAD GROUPS)
#   owner_group_id  = module.access.group_ids["acr_owner"]
#   admin_group_id  = module.access.group_ids["acr_admins"]
#   devops_group_id = module.access.group_ids["acr_devops"]

#   # 3. SKU & CORE SETTINGS
#   /* Allowed: Basic | Standard | Premium (case-sensitive) */
#   sku           = "Premium"
#   admin_enabled = false

#   identity_type = "SystemAssigned"

#   # 4. NETWORK ACCESS
#   /* Public access enabled for UAT/debugging; Set false in PROD when using Private Endpoint only. */
#   public_network_access_enabled = true

#   allowed_ips = var.allowed_ips # ["49.37.211.93/32"]

#   # 5. PRIVATE NETWORKING (OPTIONAL)
#   /* Enables private endpoint for ACR to provide secure, private access via VNet; 
#   requires Premium SKU (or supported tier) and uses specified subnet and private DNS zone for name resolution */
#   enable_private_endpoint = true
#   private_subnet_id       = module.virtual_network.subnet_lookup["private_endpoint"]
#   private_dns_zone_id     = module.private_dns.zone_ids["privatelink.azurecr.io"]

#   # 6. PREMIUM FEATURES (USE ONLY IF SKU = Premium)
#   /* CMK for customer-managed encryption */
#   enable_cmk = false
#   acr_cmk_id = null
#   # acr_cmk_id = module.key_vault.acr_cmk_id   

#   /* Premium-only features: Data endpoint for private/optimized data transfer, geo-replication for multi-region availability and disaster recovery, 
#   and zone redundancy for high availability within a region */
#   enable_data_endpoint    = false
#   enable_georeplication   = false
#   zone_redundancy_enabled = false

#   # 7. IMAGE MANAGEMENT: /* Image Lifecycle: Cleanup of untagged images only */
#   enable_retention_policy = false
#   retention_days          = 7

#   # 8. SECURITY SETTINGS
#   export_policy_enabled  = true /* Controls whether ACR images can be exported to external storage (e.g., Azure Blob for backup/archival) */
#   anonymous_pull_enabled = false /* Allows unauthenticated (public) pull access to container images when enabled */

#   # 9. TOKEN / AUTH (ADVANCED):
#   /* Enables token-based authentication for ACR (primarily for token-based access) with credentials automatically stored in Key Vault,
#    allowing fine-grained, secure access control without using admin credentials */
#   enable_token       = true
#   key_vault_id_token = module.key_vault.key_vault_id

#   # 10. WEBHOOK / INTEGRATION
#   enable_webhook = false /* Enables ACR webhook notifications for events like image push/pull (e.g., Slack/CI/CD integration) */
#   webhook_uri    = "https://hooks.slack.com/services/XXXX" /*  Endpoint URL where ACR sends event notifications when webhook is enabled */

#   depends_on = [
#     module.virtual_network,
#     module.private_dns,
#     module.access
#   ]
# }

# # K8s
# module "aks" {
#   source = "../../modules/az-compute/aks"

#   # 1. BASIC INFO
#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}-${local.workload}-aks"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # 2. ACCESS (AAD GROUPS)
#   owner_group_id  = module.access.group_ids["aks_admins"]
#   devops_group_id = module.access.group_ids["aks_devops"]

#   # 3. VERSION & SKU
#   kubernetes_version = "1.35"
#   sku_tier           = "Standard"

#   # 4. NETWORKING MODE
#   dns_prefix = "${local.env}aks"

#   # Case 1 — Private AKS (System DNS)
#   private_cluster_enabled = true
#   use_custom_private_dns  = false

#   # Case 2 — Private AKS (Custom DNS)
#   # private_cluster_enabled             = true
#   # use_custom_private_dns              = true
#   # private_dns_zone_id                 = module.private_dns.zone_ids["privatelink.centralindia.azmk8s.io"]  

#   # Case 3 — Public AKS
#   # private_cluster_enabled             = false
#   # use_custom_private_dns              = false

#   # --- API Access ---
#   api_server_access_profile = {
#     authorized_ip_ranges = concat(
#       ["10.0.1.0/27"],
#       var.allowed_ips
#     )
#   }

#   network_profile = {
#     network_plugin = "azure"
#     network_policy = "calico"
#   }

#   subnet_id = module.virtual_network.subnet_lookup["aks"]

#   # 5. IDENTITY & SECURITY
#   identity = {
#     /* AKS cluster managed identity (control plane identity); Used for Azure resource operations (LB, networking, node pools); Azure creates and manages this automatically */
#     type = "SystemAssigned"
#   }

#   /* Node (kubelet) managed identity; Used by AKS nodes to access Azure resources; Examples: pull images from ACR, mount disks/files; Empty {} = Azure auto-creates and manages it */
#   kubelet_identity = {}

#   /* Forces authentication via Azure AD (Entra ID) instead of static credentials */
#   local_account_disabled = true

#   /* Enables Azure AD-based RBAC for AKS, allowing access control using Azure roles and identities instead of Kubernetes native RBAC alone */
#   aad_rbac = {
#     enabled            = true
#     azure_rbac_enabled = true
#   }

#   /* Enables Kubernetes RBAC for managing permissions within the cluster */
#   role_based_access_control_enabled = true

#   # 6. INTEGRATIONS  
#   acr_id               = module.acr.acr_id
#   enable_key_vault_csi = true
#   key_vault_id         = module.key_vault.key_vault_id


#   # 7. PLATFORM FEATURES (MISSING ONES)

#   /* Optional disk encryption using customer-managed keys (null = not enabled) */
#   disk_encryption_set_id = null

#   /* Disables automatic HTTP application routing (DNS + ingress add-on for quick public exposure of apps) */
#   http_application_routing_enabled = false

#   # 8. MONITORING & LOGGING
#   /* Enables monitoring integration for AKS (required for logs, metrics, and diagnostics collection) */
#   enable_monitoring = true

#   # Case 1: Disables OMS agent → no logs/metrics sent to Log Analytics (basic or no monitoring setup) */
#   # enable_oms_agent           = false
#   # log_analytics_workspace_id = null

#   # Case 2: Enables OMS agent → sends AKS logs and metrics to specified Log Analytics Workspace for monitoring and insights */
#   enable_oms_agent           = true
#   log_analytics_workspace_id = module.log_analytics.workspace_id

#   /* Defines Data Collection Rule (DCR) and its association for advanced log/metric collection configuration in AKS */
#   aks_dcr_name        = "${local.env}-${local.workload}-aks-dcr"
#   aks_dcr_association = "${local.env}-${local.workload}-aks-dcr-assoc"

#   # 9. UPGRADES & MAINTENANCE
#   enable_maintenance_window = false

#   automatic_upgrade_channel = null /* patch/rapid/node-image/stable/null  */
#   node_os_upgrade_channel   = "None" /* Unmanaged/SecurityPatch/NodeImage/None */

#   auto_scaler_profile = {
#     /* When multiple node pools are similar (same size/labels), AKS cluster autoscaler tries to distribute scale-out across them instead of scaling only one pool. */
#     balance_similar_node_groups = false
#   }

#   # 10. DEFENDER / SECURITY ADDONS
#   enable_defender = false

#   defender_workspace_id = null
#   # defender_workspace_id = module.log_analytics.workspace_id
#   # defender_workspace_id = "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/ws"  +

#   # 11. STORAGE  
#   storage_profile = {
#     blob_driver_enabled = true
#   }

#   # 12. NODE CONFIG
#   node_resource_group_name = "${local.env}-${local.workload}-aks-node-rg"

#   # NODE POOL (optional inline structure)
#   default_node_pool = {
#     name                 = "system"
#     node_count           = 1
#     vm_size              = "Standard_B2s_v2"
#     auto_scaling_enabled = false
#     min_count            = 1
#     max_count            = 3
#     vnet_subnet_id       = module.virtual_network.subnet_lookup["aks"]
#   }

#   enable_worker_nodepool = false

#   # NODE POOLS (extra)
#   node_pools = {
#     workernode = {
#       name                 = "workernode1"
#       vm_size              = "Standard_D2s_v4"
#       node_count           = 1
#       auto_scaling_enabled = false
#       min_count            = 1
#       max_count            = 3
#       vnet_subnet_id       = module.virtual_network.subnet_lookup["aks"]
#     }
#   }

#   # 13. ADVANCED FEATURES
#   /* Enables AKS to publish an OIDC identity endpoint for secure token-based authentication */
#   oidc_issuer_enabled = true

#   /* Allows pods to use Azure AD Workload Identity to access Azure resources without secrets */
#   workload_identity_enabled = true

#   /* Uses Microsoft-supported Kubernetes support plan and disables remote command execution on cluster nodes for security */
#   support_plan        = "KubernetesOfficial"
#   run_command_enabled = false

#   # 14. EXTENSIONS
#   extensions = {}

#   # 15. POLICY & SAFEGUARD
#   # Case 1 — Safeguard OFF, Policy OFF (Disables Azure Policy and deployment safeguards → no governance or enforcement applied on AKS resources */)
#   azure_policy_enabled = false
#   deployment_safeguard = null

#   # Case 2 — Safeguard ON (REQUIRED: Policy ON) (Enables Azure Policy with deployment safeguard → enforces or warns on policy violations during deployments)
#   # azure_policy_enabled = true
#   # deployment_safeguard = {
#   #   level = "Warn" /* "Warn"/"Enforce" */
#   # }

#   # 16. TRUSTED ACCESS  
#   /* Disables trusted access → AKS will not allow integrated access from trusted Azure services (e.g., Backup) */
#   enable_trusted_access = false

#   /* Defines trusted access configuration allowing specific Azure services (e.g., Backup) to access AKS with scoped permissions when enabled */
#   trusted_access = {
#     backup_service = {
#       name               = "backup"
#       source_resource_id = "/subscriptions/xxx/providers/Microsoft.DataProtection/backupVaults/vault1"
#       roles              = ["Microsoft.DataProtection/backupVaults/backup/read"]
#     }
#   }

#   # 17. DEPENDENCIES
#   depends_on = [
#     module.rg,
#     module.virtual_network,
#     module.key_vault,
#     module.acr,
#     module.private_dns,
#     module.log_analytics,
#     module.access
#   ]
# }


# # Linux App Service Plan
# module "appservice_plan_linux" {
#   source = "../../modules/az-appserviceplan"


#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}-${local.workload}-lnx-srvplan"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   os_type  = "Linux"
#   sku_name = "P0v3"

#   zone_balancing_enabled = false
# }

# # Appservice - Webapp
# module "app_service" {
#   source = "../../modules/az-appservice_webapp"

#   # 1. NAMING / BASICS
#   env      = local.env
#   workload = local.workload

#   name                = "${local.workload}-fe-lnx-webapp"
#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   # 2. ACCESS (AAD / RBAC)
#   owner_group_id  = module.access.group_ids["app_admins"]
#   devops_group_id = module.access.group_ids["app_devops"]

#   # 3. COMPUTE (PLAN + IDENTITY)
#   app_service_plan_id = module.appservice_plan_linux.app_service_plan_id

#   https_only    = true
#   identity_type = "SystemAssigned"

#   # 4. NETWORKING
#   subnet_id = module.virtual_network.subnet_lookup["app"]

#   # Case 1: Public app service
#   public_network_access_enabled = true
#   app_access_mode               = "public"
#   private_dns_zone_ids          = []

#   # Case 2: Private app service
#   # public_network_access_enabled = false
#   # app_access_mode               = "private"
#   # private_dns_zone_ids = [
#   #   module.private_dns.zone_ids["privatelink.azurewebsites.net"]
#   # ]
#   # private_endpoint_subnet_id = module.virtual_network.subnet_lookup["pe"]

#   ip_restrictions = [
#     {
#       name       = "office-ip"
#       ip_address = "49.38.219.93/32"
#       priority   = 100
#       action     = "Allow"
#     }
#   ]

#   # SCM restriction (VALID placement)
#   scm_use_main_ip_restriction = false           # Enables/disables inheritance of main site IP rules for SCM (Kudu access)
#   scm_allowed_ips             = var.allowed_ips # List of allowed IPs that can access SCM (Kudu/Deployment site)

#   # Backend API endpoint used by the application for internal service communication
#   api_url = "http://172.21.0.34"

#   # 5. DOMAIN / DNS / CERT
#   domain        = "company.co.in"
#   prod_hostname = "cloudops"
#   uat_hostname  = "uat-cloudops"

#   key_vault_id        = module.key_vault.key_vault_id
#   key_vault_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]
#   godaddy_secret_name = "godaddy-apikey"

#   # 6. STORAGE / LOGGING
#   /* Integrates storage account for logging: stores application logs and HTTP access logs in dedicated containers using SAS URLs */
#   storage_account_id = module.appservice_storage_account.storage_account_id

#   app_logs_sas_url  = module.appservice_storage_account.sas_urls["app-logs"]
#   http_logs_sas_url = module.appservice_storage_account.sas_urls["http-logs"]

#   # 7. MONITORING (TOGGLE ZONE)
#   /* Controls application monitoring: enables Application Insights for telemetry and links logs to Log Analytics Workspace for centralized observability */
#   enable_app_insights        = true
#   app_insights_name          = "${local.env}${local.workload}-appi"
#   log_analytics_workspace_id = module.log_analytics.workspace_id

#   # 8. BACKUP (TOGGLE ZONE)
#   /* Configures automated backups for the App Service, storing snapshots in a storage account with defined schedule, retention, and recovery settings */
#   backup_config = {
#     enabled                  = false
#     storage_account_url      = module.appservice_storage_account.sas_urls["backups"]
#     frequency_interval       = 1
#     frequency_unit           = "Day"
#     retention_period_days    = 7
#     keep_at_least_one_backup = true
#     start_time               = "2026-04-25T02:00:00Z"
#   }

#   # 9. DEPENDENCIES
#   depends_on = [
#     module.key_vault,
#     module.virtual_network,
#     module.private_dns,
#     module.appservice_plan_linux,
#     module.access
#   ]
# }

# Optional:
# module "frontdoor" {
#   source = "../../modules/az-frontdoor"

#   # toggles Front Door creation
#   enable_frontdoor = true

#   # Front Door SKU (Standard/Premium)
#   sku_name = "Standard_AzureFrontDoor"          

#   name                = "${local.workload}-frontdoor"
#   resource_group_name = module.rg.resource_group_name

#   tags = module.rg.tags

#   # KV used for secrets/RBAC if required
#   key_vault_id        = module.key_vault.key_vault_id
#   godaddy_secret_name = "godaddy-apikey"

#   apps = {
#     cloudops = {
#       enabled        = true                                                       # enable this backend (prod app)
#       host_name      = "cloudops.company.co.in"                                    # Front Door custom domain (FULL FQDN)
#       domain         = "company.co.in"                                             # DNS zone
#       cert_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]   # TLS cert secret
#        backend_primary = "cloudops-fe-lnx-webapp.azurewebsites.net"

#       enable_dr = false
#       backend_secondary  = "cloudops-fe-lnx-webapp-dr.azurewebsites.net"
#     }

#     uat_cloudops = {
#       enabled        = false
#       host_name      = "uat-cloudops.company.co.in"
#       domain         = "company.co.in"
#       cert_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]
#       backend_primary    = "cloudops-fe-lnx-webapp-uat.azurewebsites.net"

#       enable_dr = false
#       backend_secondary  = "uat-cloudops-app-fe-dr.azurewebsites.net"
#     }
#   }

#   depends_on = [
#     module.key_vault,
#     module.virtual_network,
#     module.private_dns
#   ]  
# }

