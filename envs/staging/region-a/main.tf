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
  env      = "uat"
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
    environment = "uat",
    location    = "centralindia"
  }
}

# Logic App API Connection for Gmail
module "gmail_api_connection" {
  source = "../../../modules/az-logic-app-api-connection"

  subscription_id = var.subscription_id

  api_connection_name = "${local.env}-${local.workload}-gmailapi"

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
}

# # Network module for hub-spoke setup (VNet, Subnet, NSG, NSG Rules)
# module "virtual_network" {
#   source = "../../../modules/az-network"

#   env      = local.env
#   workload = local.workload

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Controls internet access from subnet: true = allows default outbound internet, false = blocks unless explicitly configured (e.g., NAT/Firewall)
#   default_outbound_access_enabled = false

#   allowed_sources = var.allowed_ips

#   # VNet CIDR
#   # {VNet key = hub\spoke} must match the corresponding key in subnet_address_space to map subnets to the correct VNet
#   vnet_address_space = {
#     hub  = ["10.0.0.0/16"]
#     app  = ["172.16.0.0/16"]
#     data = ["192.168.0.0/16"]
#   }

#   # Subnet CIDR
#   # {Subnet key = AzureFirewallSubnet\app} must align with the VNet key to ensure subnets are created within the correct VNet
#   subnet_address_space = {
#     hub = {
#       AzureBastionSubnet = {
#         cidr = ["10.0.1.0/26"]
#         tags = { type = "infra" }
#       }
#       mgmt = {
#         cidr = ["10.0.1.64/28"]
#         tags = { type = "workload" }
#       }
#     }

#     app = {
#       vmss = {
#         cidr = ["172.16.1.0/24"]
#         tags = { type = "workload" }
#       }
#       AzureLoadBalancer = {
#         cidr = ["172.16.2.0/24"]
#         tags = { type = "infra" }
#       }
#       functions = {
#         cidr = ["172.16.3.0/24"]
#         tags = { type = "infra" }

#         delegation = {
#           name = "delegation"

#           service_delegation = {
#             name = "Microsoft.Web/serverFarms"
#             actions = [
#               "Microsoft.Network/virtualNetworks/subnets/join/action"
#             ]
#           }
#         }
#       }
#     }

#     data = {
#       db = {
#         cidr = ["192.168.1.0/24"]
#         tags = { type = "workload" }
#       }
#     }
#   }
# }

# # Network - VNet Peering
# module "vnet_peering" {
#   source = "../../../modules/az-vnet-peering"


#   peerings = {
#     hub_to_app = {
#       name                    = "${local.env}-hub-to-app"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["hub"].name
#       remote_vnet_id          = module.virtual_network.vnets["app"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     },

#     app_to_hub = {
#       name                    = "${local.env}-app-to-hub"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["app"].name
#       remote_vnet_id          = module.virtual_network.vnets["hub"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     },

#     hub_to_data = {
#       name                    = "${local.env}-hub-to-data"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["hub"].name
#       remote_vnet_id          = module.virtual_network.vnets["data"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     },

#     data_to_hub = {
#       name                    = "${local.env}-data-to-hub"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["data"].name
#       remote_vnet_id          = module.virtual_network.vnets["hub"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     },

#     app_to_data = {
#       name                    = "${local.env}-app-to-data"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["app"].name
#       remote_vnet_id          = module.virtual_network.vnets["data"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     },

#     data_to_app = {
#       name                    = "${local.env}-data-to-app"
#       resource_group          = module.rg.resource_group_name
#       vnet_name               = module.virtual_network.vnets["data"].name
#       remote_vnet_id          = module.virtual_network.vnets["app"].id
#       allow_vnet_access       = true
#       allow_forwarded_traffic = true
#       allow_gateway_transit   = false
#       use_remote_gateways     = false
#     }
#   }
#   depends_on = [module.virtual_network]
# }

# # Network - Private DNS
# module "private_dns" {
#   source = "../../../modules/az-dns/private"

#   resource_group_name = module.rg.resource_group_name

#   /* list of private DNS zones to create */
#   zones = [
#     "privatelink.blob.core.windows.net",
#     "privatelink.queue.core.windows.net", /* Private DNS zone for Azure Storage (Queue) private endpoints */
#     "privatelink.vaultcore.azure.net",
#     "internal.hbcdev.co.in"
#   ]

#   /* VNets to link with DNS zones for name resolution */
#   vnet_ids = [
#     module.virtual_network.vnets["hub"].id,
#     module.virtual_network.vnets["app"].id,
#     module.virtual_network.vnets["data"].id
#   ]

#   depends_on = [
#     module.virtual_network
#   ]
# }

# # Security - Key Vault
# module "key_vault" {
#   source = "../../../modules/az-keyvault"

#   name = var.key_vault_name /* "${local.env}-${local.workload}-kv-17" = Key Vault names must be globally unique across Azure. */

#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   owner_group_id  = module.access.group_ids["kv_admins"]
#   devops_group_id = module.access.group_ids["kv_devops"]

#   /* false = uses access policies, true = uses RBAC */
#   rbac_authorization_enabled = true

#   /* true = creates access for current user, false = no access policy */
#   create_access_policy_me = false

#   /* standard = basic features, premium = supports HSM-backed keys */
#   sku_name = "premium" # Standard or Premium

#   soft_delete_retention_days = 7 /* days to retain deleted items (7–90) */
#   purge_protection_enabled   = false /* true = prevents permanent deletion, false = allows purge */

#   enabled_for_deployment          = true /* true = allows VM deployment access */
#   enabled_for_template_deployment = true /* true = allows ARM template access */

#   enable_private_endpoint = true
#   private_subnet_id       = module.virtual_network.subnet_lookup["mgmt"]
#   private_dns_zone_id     = module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]

#   public_network_access_enabled = true /* true = allows public access, false = private only */

#   network_acls_default_action = "Deny" /* Deny = block all except allowed, Allow = open access */
#   allowed_ip_ranges           = var.allowed_ips # ["49.37.211.93/32"] /* allowed public IPs */

#   /*   For subnet restrictions, ensure the subnets exist and are correctly referenced.
#   service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module. */
#   allowed_subnet_ids = [
#     module.virtual_network.subnet_lookup["mgmt"],
#     module.virtual_network.subnet_lookup["vmss"],
#     module.virtual_network.subnet_lookup["functions"],
#     module.virtual_network.subnet_lookup["db"]
#   ]

#   # Security - SSH Key
#   /* stores SSH public key as secret */
#   ssh_secret_name = "linux-ssh-public-key"
#   ssh_public_key  = file("${path.module}/../ssh/id_rsa.pub")

#   # Security - Secrets
#   /* key-value secrets stored in Key Vault */
#   secrets = {
#     localadmin-credentials = jsonencode({
#       admin-username = "HBAdmin",
#       admin-password = "Qwerty123!",
#     })

#     mssql-credentials = jsonencode({
#       username = "sqladmin"
#       password = "SQLP@ssw0rd!23!"
#     })

#     /* Stores GoDaddy API credentials (API Key and Secret) as a JSON-encoded string, typically used for programmatic DNS management or domain automation */
#     godaddy-apikey = jsonencode({
#       Key    = "hkHptCfQoPVe_GLheXScX4sHsSsNBu2Y3qj"
#       Secret = "ECkifJCPVySofRBCAqjG2Y"
#     })
#   }

#   # Security - Certificates
#   /* imports certificates from PFX */
#   certificates = [
#     {
#       name     = "wildcard-cert"
#       pfx_path = "./../certs/certificate.pfx"
#       password = "Y12345Z"
#     },
#     {
#       name     = "internal-wildcard-cert"
#       pfx_path = "./../certs/internal_certificate.pfx"
#       password = "Y12345Z"
#     }
#   ]

#   # Monitoring - Diagnostics
#   audit_storage_account_name = module.diag_storage_account.storage_account_name
#   audit_storage_account_rg   = module.rg.resource_group_name

#   # depends_on ensures storage account is created before enabling diagnostics
#   depends_on = [
#     module.diag_storage_account,
#     module.private_dns,
#     module.virtual_network,
#     module.access
#   ]
# }

# # Storage - diagnostics
# module "diag_storage_account" {
#   source = "../../../modules/az-storage"

#   storage_account_name = var.diag_storage_account_name

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
#     module.virtual_network.subnet_lookup["vmss"],
#     module.virtual_network.subnet_lookup["db"],
#     module.virtual_network.subnet_lookup["mgmt"]
#   ]

#   allowed_ip_rules = var.allowed_ips_plain # ["49.37.211.93"] /* allows access from specific public IPs */

#   enable_private_endpoint   = false
#   private_subnet_id         = module.virtual_network.subnet_lookup["mgmt"]
#   blob_private_dns_zone_id  = module.private_dns.zone_ids["privatelink.blob.core.windows.net"]
#   queue_private_dns_zone_id = module.private_dns.zone_ids["privatelink.queue.core.windows.net"]

#   # Lifecycle Enabled
#   /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
#   lifecycle_rules = [
#     {
#       name   = "diag-cleanup"
#       prefix = ["bootdiagnostics", "insights-logs"]
#       days   = 1
#     }
#   ]

#   depends_on = [
#     module.virtual_network
#   ]
# }

# # Network Security - Azure Bastion
# module "bastion" {
#   source = "../../../modules/az-bastion"

#   enable_bastion = false

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

# # Windows SQL VM Deployment Module
# module "sql_win_vm" {
#   source = "../../../modules/az-compute/sql_in_vm"

#   env      = local.env
#   workload = local.workload

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   vm_name  = "${local.env}-${local.workload}-sql"
#   vm_count = 1

#   vm_size = "Standard_B2s_v2"

#   image_publisher = "MicrosoftSQLServer"
#   image_offer     = "sql2017-ws2019"
#   image_sku       = "express"
#   image_version   = "14.1.250208"

#   subnet_id = module.virtual_network.subnet_lookup["db"]

#   internal_zone_name = "internal.hbcdev.co.in"

#   private_ip_allocation = "Dynamic"

#   os_disk_storage_type = "Standard_LRS"
#   os_disk_size_gb      = 127

#   enable_public_ip = true /* true  → VM gets public IP (direct internet access) */

#   enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */
#   availability_set_name   = "biztalk-avset"

#   zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

#   # Controls boot diagnostics storage
#   enable_boot_diagnostics               = false
#   boot_diagnostics_mode                 = "none" /* "none", "existing", or "create" */
#   boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

#   # enable_boot_diagnostics               = true
#   # boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
#   # boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

#   /*Fetches admin credentials from Key Vault instead of hardcoding
#   Helps secure VM username/password */
#   key_vault_id                       = module.key_vault.key_vault_id /* change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password */
#   localadmin_credentials_secret_name = "localadmin-credentials"

#   enable_asg = false

#   # enable_lb = false                       /* true  → attaches VM NICs to Load Balancer backend pool */

#   # Scenario 1: Existing LB
#   # lb_name              = "existing-lb-name"
#   # lb_backend_pool_name = "backend-pool-name"

#   # Scenario 2: New LB scenario (created in same Terraform)
#   # lb_backend_pool_id = module.loadbalancer.backend_pool_id

#   license_type = "Windows_Server" # "Windows_Server", "RHEL", "SLES", "Windows_Client"; adjust based on your image and licensing needs

#   # data_disks = [
#   #   {
#   #     size_gb      = 127
#   #     lun          = 0
#   #     caching      = "ReadWrite"
#   #     storage_type = "Standard_LRS"
#   #   }
#   # ]

#   # Backup configuration
#   enable_backup = false /* true  → enables VM backup using Recovery Services Vault */

#   # Recovery Serivce Vault Configuration
#   recovery_services_vault_name = "existing-rsv"
#   backup_policy_vm             = "existing-policy"

#   depends_on = [
#     module.key_vault,
#   ]
# }

# # Windows VMSS Deployment Module
# module "vmss" {
#   source = "../../../modules/az-compute/vmss"

#   env      = local.env
#   workload = local.workload

#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name

#   tags = module.rg.tags

#   vm_size = "Standard_B2s_v2"

#   vmss_name = "${local.env}-wvmss"
#   instances = 1

#   image_publisher = "MicrosoftWindowsServer"
#   image_offer     = "WindowsServer"
#   image_sku       = "2019-Datacenter"
#   image_version   = "latest"

#   license_type = "Windows_Server"
#   upgrade_mode = "Automatic"

#   subnet_id = module.virtual_network.subnet_lookup["vmss"]

#   enable_public_ip = false

#   enable_lb = true

#   # Scenario 1: Existing LB
#   # load_balancers = [
#   #   {
#   #     lb_name              = "existing-public-lb"
#   #     lb_backend_pool_name = "lb-backend-pool"
#   #   }
#   # ]

#   # Scenario 2: New LB scenario (created in same Terraform)
#   # lb_backend_pool_id   = null
#   lb_backend_pool_ids = [
#     module.loadbalancer-public.backend_pool_id,
#     module.loadbalancer-private.backend_pool_id
#   ]
#   enable_asg = false

#   key_vault_id                       = module.key_vault.key_vault_id
#   localadmin_credentials_secret_name = "localadmin-credentials"

#   certificate_priv_secret_url = module.key_vault.certificate_secret_ids["internal-wildcard-cert"]
#   certificate_pub_secret_url  = module.key_vault.certificate_secret_ids["wildcard-cert"]

#   enable_dns_record     = true
#   private_dns_zone_name = "internal.hbcdev.co.in"
#   api_dns_name          = "uat-eda-api"
#   lb_private_ip         = module.loadbalancer-private.private_ip

#   public_domain = "hbcdev.co.in"

#   enable_boot_diagnostics               = false
#   boot_diagnostics_mode                 = "none"
#   boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

#   queue_storage_account_name = module.eda_storage_account.storage_account_name

#   # enable_boot_diagnostics               = true
#   # boot_diagnostics_mode                 = "existing"
#   # boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

#   os_disk_storage_type = "Standard_LRS"
#   os_disk_size_gb      = 127

#   # data_disks = [
#   #   {
#   #     size_gb      = 127
#   #     lun          = 0
#   #     caching      = "ReadWrite"
#   #     storage_type = "Standard_LRS"
#   #   }
#   # ]

#   zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

#   enable_backup = false

#   enable_autoscale           = false
#   autoscale_min_capacity     = 1
#   autoscale_max_capacity     = 3
#   autoscale_default_capacity = 1

#   autoscale_cpu_scale_out_threshold = 70
#   autoscale_cpu_scale_in_threshold  = 30

#   autoscale_cooldown = "PT5M"

#   enable_autoscale_notifications = false
#   autoscale_notification_email   = "admin@company.com"

#   depends_on = [
#     module.loadbalancer-private,
#     module.key_vault,
#     module.eda_storage_account
#   ]
# }

# # Load Balancer Module
# module "loadbalancer-private" {
#   source = "../../../modules/az-loadbalancer"

#   env      = local.env
#   workload = local.workload

#   lb_name = "${local.env}-${local.workload}-lb-priv" # change to "${local.env}-lb-priv" for private LB

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Public IP
#   allocation_method = "Static"
#   sku               = "Standard"

#   # LB Configuration
#   sku_name         = "Standard" # Standard or Basic
#   frontend_ip_type = "Private"  # Public or Private;  For Private LB: use a valid subnet output (e.g., spoke/web); update the key if your subnet naming differs.
#   # subnet_id        = null                 # Empty means Public LB
#   subnet_id = module.virtual_network.subnet_lookup["AzureLoadBalancer"]

#   private_dns_zone_name = "internal.hbcdev.co.in"

#   # GoDaddy DNS
#   enable_external_dns = false

#   key_vault_id        = null
#   godaddy_secret_name = null

#   domain        = null
#   hostname_only = null
#   custom_domain = null

#   depends_on = [
#     module.private_dns,
#     module.key_vault
#   ]
# }

# module "loadbalancer-public" {
#   source = "../../../modules/az-loadbalancer"

#   env      = local.env
#   workload = local.workload

#   lb_name = "${local.env}-${local.workload}-lb-pub" # change to "${local.env}-lb-priv" for private LB

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Public IP
#   allocation_method = "Static"
#   sku               = "Standard"

#   # LB Configuration
#   sku_name         = "Standard" # Standard or Basic
#   frontend_ip_type = "Public"   # Public or Private;  For Private LB: use a valid subnet output (e.g., spoke/web); update the key if your subnet naming differs.
#   subnet_id        = null       # Empty means Public LB
#   # subnet_id = module.virtual_network.subnet_lookup["AzureLoadBalancer"]

#   # GoDaddy DNS
#   enable_external_dns = true

#   key_vault_id        = module.key_vault.key_vault_id
#   godaddy_secret_name = "godaddy-apikey"

#   domain        = "hbcdev.co.in"
#   hostname_only = "uat-eda-api"
#   custom_domain = "uat-eda-api.hbcdev.co.in"

#   depends_on = [
#     module.private_dns,
#     module.key_vault
#   ]
# }

# # NAT Gateway Module
# module "nat_app" {
#   source = "../../../modules/az-nat-gateway"

#   name                = "${local.env}-${local.workload}-natgw-app"
#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   enable_nat_gateway      = true
#   enable_public_ip        = true
#   enable_public_ip_prefix = false

#   subnet_ids = {
#     vmss = module.virtual_network.subnet_lookup["vmss"]
#   }
# }

# # static web app module
# module "static_web_app" {

#   source = "../../../modules/az-static-web-app"

#   name                = "${local.env}-${local.workload}-swa-r1"
#   location            = "eastasia"
#   resource_group_name = module.rg.resource_group_name

#   tags = module.rg.tags

#   api_url = "https://uat-eda-api.hbcdev.co.in"

#   custom_domain = "uat-eda.hbcdev.co.in"
#   domain        = "hbcdev.co.in"
#   hostname_only = "uat-eda"

#   tm_custom_domain = "eda.hbcdev.co.in"

#   key_vault_id        = module.key_vault.key_vault_id
#   godaddy_secret_name = "godaddy-apikey"

#   depends_on = [
#     module.key_vault
#   ]
# }


# # Storage Account for EDA application data and queues
# module "eda_storage_account" {
#   source = "../../../modules/az-storage"

#   storage_account_name = var.eda_storage_account_name

#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   account_kind          = "StorageV2"
#   account_tier          = "Standard"
#   replication_type      = "LRS"
#   dns_endpoint_type     = "Standard"
#   public_network_access = true

#   blob_versioning_enabled         = false
#   blob_delete_retention_days      = 1
#   container_delete_retention_days = 1

#   allowed_subnet_ids = [
#     module.virtual_network.subnet_lookup["vmss"],
#     module.virtual_network.subnet_lookup["functions"]
#   ]

#   allowed_ip_rules = var.allowed_ips_plain

#   enable_private_endpoint   = true
#   private_subnet_id         = module.virtual_network.subnet_lookup["mgmt"]
#   blob_private_dns_zone_id  = module.private_dns.zone_ids["privatelink.blob.core.windows.net"]
#   queue_private_dns_zone_id = module.private_dns.zone_ids["privatelink.queue.core.windows.net"]

#   containers = []

#   enable_queue = true

#   queues = [
#     "orders-queue"
#   ]

#   # Queue logging values directly here
#   queue_logging_read    = true
#   queue_logging_write   = true
#   queue_logging_delete  = true
#   queue_logging_version = "1.0"

#   depends_on = [
#     module.virtual_network
#   ]
# }

# # App Service Plan for Function App
# module "appservice_plan_windows" {
#   source = "../../../modules/az-appserviceplan"


#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}-${local.workload}-win-srvplan"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   os_type  = "Windows" /* Windows or Linux */
#   sku_name = "P0v3"

#   zone_balancing_enabled = false
# }

# # Azure Function App Module
# module "function_app" {
#   source = "../../../modules/az-function-app"

#   function_app_name = "${local.env}-${local.workload}-funcapp"

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location

#   service_plan_id = module.appservice_plan_windows.app_service_plan_id

#   storage_account_name = module.eda_storage_account.storage_account_name
#   storage_account_id   = module.eda_storage_account.storage_account_id

#   allowed_ip_rules = var.allowed_ips

#   subnet_id = module.virtual_network.subnet_lookup["functions"]

#   key_vault_id    = module.key_vault.key_vault_id
#   sql_secret_name = "mssql-credentials"

#   storage_connection_string = module.eda_storage_account.primary_connection_string
#   sql_connection_string     = "Server=tcp:uat-eda-sql01.internal.hbcdev.co.in,1433;Database=OrdersDB;User Id=sqladmin;Password=SQLP@ssword!23!;Encrypt=True;TrustServerCertificate=True;"
#   queue_name = "orders-queue"
#   logic_app_callback_url    = module.logic_app.callback_url

#   tags = module.rg.tags

#   depends_on = [
#     module.key_vault,
#     module.private_dns,
#     module.logic_app
#   ]
# }

# # Logic App (consumption) Module
# module "logic_app" {
#   source = "../../../modules/az-logicapp"

#   subscription_id = var.subscription_id

#   logic_app_name = "${local.env}-${local.workload}-logicapp"

#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name

#   gmail_api_connection_id   = module.gmail_api_connection.gmail_api_connection_id
#   gmail_api_connection_name = module.gmail_api_connection.gmail_api_connection_name

#   notification_emails = [
#     "chandranchrist@gmail.com"
#   ]

#   tags = module.rg.tags

#   depends_on = [
#     module.gmail_api_connection
#   ]
# }

# # Traffic Manager Module for global routing and failover between primary and DR static web apps
# module "traffic_manager" {

#   source = "../../../modules/az-trafficmanager"

#   traffic_manager_name = "${local.env}-${local.workload}-tm"
#   resource_group_name  = module.rg.resource_group_name

#   create_traffic_manager  = true
#   create_primary_endpoint = true

#   traffic_routing_method = "Priority"

#   dns_relative_name = "eda-ui"

#   ttl = 30

#   create_dns_record = true

#   domain        = "hbcdev.co.in"
#   hostname_only = "eda"

#   monitor_protocol = "HTTPS"
#   monitor_port     = 443
#   monitor_path     = "/"

#   # primary_endpoint_name = "primary-swa"
#   # primary_custom_domain = "uat-eda.hbcdev.co.in"

#   # Use SWA DEFAULT hostname
#   primary_endpoint_name     = "primary-swa"
#   primary_endpoint_location = "eastasia"
#   primary_swa_priority      = "1"
#   primary_swa_enabled       = true

#   primary_target            = module.static_web_app.default_host_name
#   primary_static_web_app_id = module.static_web_app.static_web_app_id

#   enable_dr = false

#   key_vault_id        = module.key_vault.key_vault_id
#   godaddy_secret_name = "godaddy-apikey"

#   tags = module.rg.tags

#   validation_dependency = module.static_web_app.tm_domain_validation_completed

#   depends_on = [
#     module.static_web_app
#   ]
# }

