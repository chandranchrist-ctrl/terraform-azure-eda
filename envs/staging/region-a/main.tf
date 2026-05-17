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

  allowed_sources = var.allowed_ips

  # VNet CIDR
  # {VNet key = hub\spoke} must match the corresponding key in subnet_address_space to map subnets to the correct VNet
  vnet_address_space = {
    hub  = ["10.0.0.0/16"]
    app  = ["172.16.0.0/16"]
    data = ["192.168.0.0/16"]
  }

  # Subnet CIDR
  # {Subnet key = AzureFirewallSubnet\app} must align with the VNet key to ensure subnets are created within the correct VNet
  subnet_address_space = {
    hub = {
      AzureBastionSubnet = {
        cidr = ["10.0.1.0/26"]
        tags = { type = "infra" }
      }
      mgmt = {
        cidr = ["10.0.1.64/28"]
        tags = { type = "workload" }
      }
    }

    app = {
      vmss = {
        cidr = ["172.16.1.0/24"]
        tags = { type = "workload" }
      }
      AzureLoadBalancer = {
        cidr = ["172.16.2.0/24"]
        tags = { type = "infra" }
      }
      functions = {
        cidr = ["172.16.3.0/24"]
        tags = { type = "infra" }

        delegation = {
          name = "delegation"

          service_delegation = {
            name = "Microsoft.Web/serverFarms"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      }
    }

    data = {
      db = {
        cidr = ["192.168.1.0/24"]
        tags = { type = "workload" }
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
      vnet_name               = module.virtual_network.vnets["hub"].name
      remote_vnet_id          = module.virtual_network.vnets["app"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    app_to_hub = {
      name                    = "${local.env}-app-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["app"].name
      remote_vnet_id          = module.virtual_network.vnets["hub"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    hub_to_data = {
      name                    = "${local.env}-hub-to-data"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub"].name
      remote_vnet_id          = module.virtual_network.vnets["data"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    data_to_hub = {
      name                    = "${local.env}-data-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["data"].name
      remote_vnet_id          = module.virtual_network.vnets["hub"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    app_to_data = {
      name                    = "${local.env}-app-to-data"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["app"].name
      remote_vnet_id          = module.virtual_network.vnets["data"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },

    data_to_app = {
      name                    = "${local.env}-data-to-app"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["data"].name
      remote_vnet_id          = module.virtual_network.vnets["app"].id
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
    "privatelink.blob.core.windows.net",
    "privatelink.queue.core.windows.net", /* Private DNS zone for Azure Storage (Queue) private endpoints */
    "privatelink.vaultcore.azure.net",
    "internal.hbcdev.co.in"
  ]

  /* VNets to link with DNS zones for name resolution */
  vnet_ids = [
    module.virtual_network.vnets["hub"].id,
    module.virtual_network.vnets["app"].id,
    module.virtual_network.vnets["data"].id
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
  private_subnet_id       = module.virtual_network.subnet_lookup["mgmt"]
  private_dns_zone_id     = module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]

  public_network_access_enabled = true /* true = allows public access, false = private only */

  network_acls_default_action = "Deny" /* Deny = block all except allowed, Allow = open access */
  allowed_ip_ranges           = var.allowed_ips # ["49.37.211.93/32"] /* allowed public IPs */

  /*   For subnet restrictions, ensure the subnets exist and are correctly referenced.
  service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module. */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["mgmt"],
    module.virtual_network.subnet_lookup["vmss"],
    module.virtual_network.subnet_lookup["functions"],
    module.virtual_network.subnet_lookup["db"]
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

    /* Stores GoDaddy API credentials (API Key and Secret) as a JSON-encoded string, typically used for programmatic DNS management or domain automation */
    godaddy-apikey = jsonencode({
      Key    = "hkHptCfQoPVe_GLheXScX4sHsSsNBu2Y3qj"
      Secret = "ECkifJCPVySofRBCAqjG2Y"
    })
  }

  # Security - Certificates
  /* imports certificates from PFX */
  certificates = [
    {
      name     = "wildcard-cert"
      pfx_path = "./../certs/certificate.pfx"
      password = "Y12345Z"
    },
    {
      name     = "internal-wildcard-cert"
      pfx_path = "./../certs/internal_certificate.pfx"
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
    module.virtual_network.subnet_lookup["vmss"],
    module.virtual_network.subnet_lookup["db"],
    module.virtual_network.subnet_lookup["mgmt"]
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

# Network Security - Azure Bastion
module "bastion" {
  source = "../../../modules/az-bastion"

  enable_bastion = true

  env = local.env

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  subnet_id = module.virtual_network.subnet_lookup["AzureBastionSubnet"] /* dedicated Bastion subnet */

  sku = "Standard" /* Basic or Standard (Standard = more features) */

  tunneling_enabled  = true /* true = allows native client (SSH/RDP) via Bastion */
  ip_connect_enabled = true /* true = connect using private IP */
  copy_paste_enabled = true /* true = enable clipboard */
  file_copy_enabled  = true /* true = allow file transfer */

  zones = null /* null = no zone redundancy, ["1","2","3"] = zone redundant */

  kerberos_enabled = false /* true = enable Kerberos auth, false = disabled */

  depends_on = [
    module.virtual_network
  ]
}

# Windows SQL VM Deployment Module
module "sql_win_vm" {
  source = "../../../modules/az-compute/sql_in_vm"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.env}-${local.workload}-sql"
  vm_count = 1

  vm_size = "Standard_B2s_v2"

  image_publisher = "MicrosoftSQLServer"
  image_offer     = "sql2017-ws2019"
  image_sku       = "express"
  image_version   = "14.1.250208"

  subnet_id = module.virtual_network.subnet_lookup["db"]

  internal_zone_name = "internal.hbcdev.co.in"

  private_ip_allocation = "Dynamic"

  os_disk_storage_type = "Standard_LRS"
  os_disk_size_gb      = 127

  enable_public_ip = false /* true  → VM gets public IP (direct internet access) */

  enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */
  availability_set_name   = "biztalk-avset"

  zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

  # Controls boot diagnostics storage
  enable_boot_diagnostics               = false
  boot_diagnostics_mode                 = "none" /* "none", "existing", or "create" */
  boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

  # enable_boot_diagnostics               = true
  # boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
  # boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

  /*Fetches admin credentials from Key Vault instead of hardcoding
  Helps secure VM username/password */
  key_vault_id                       = module.key_vault.key_vault_id /* change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password */
  localadmin_credentials_secret_name = "localadmin-credentials"

  enable_asg = false

  # enable_lb = false                       /* true  → attaches VM NICs to Load Balancer backend pool */

  # Scenario 1: Existing LB
  # lb_name              = "existing-lb-name"
  # lb_backend_pool_name = "backend-pool-name"

  # Scenario 2: New LB scenario (created in same Terraform)
  # lb_backend_pool_id = module.loadbalancer.backend_pool_id

  license_type = "Windows_Server" # "Windows_Server", "RHEL", "SLES", "Windows_Client"; adjust based on your image and licensing needs

  # data_disks = [
  #   {
  #     size_gb      = 127
  #     lun          = 0
  #     caching      = "ReadWrite"
  #     storage_type = "Standard_LRS"
  #   }
  # ]

  # Backup configuration
  enable_backup = false /* true  → enables VM backup using Recovery Services Vault */

  # Recovery Serivce Vault Configuration
  recovery_services_vault_name = "existing-rsv"
  backup_policy_vm             = "existing-policy"

  depends_on = [
    module.key_vault,
  ]
}

# Windows VMSS Deployment Module
module "vmss" {
  source = "../../../modules/az-compute/vmss"

  env      = local.env
  workload = local.workload

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name

  tags = module.rg.tags

  vm_size = "Standard_D2s_v5"

  vmss_name = "${local.env}-wvmss"
  instances = 1

  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2019-Datacenter"
  image_version   = "latest"

  license_type = "Windows_Server"
  upgrade_mode = "Automatic"

  subnet_id = module.virtual_network.subnet_lookup["vmss"]

  enable_public_ip = false

  enable_lb = true

  # Scenario 1: Existing LB
  # lb_name              = "existing-lb"
  # lb_backend_pool_name = "backend-pool-name"

  # Scenario 2: New LB scenario (created in same Terraform)
  # lb_backend_pool_id   = null
  lb_backend_pool_id = module.loadbalancer.backend_pool_id

  enable_asg = false

  key_vault_id                       = module.key_vault.key_vault_id
  localadmin_credentials_secret_name = "localadmin-credentials"

  certificate_secret_url = module.key_vault.certificate_secret_ids["internal-wildcard-cert"]

  enable_dns_record     = true
  private_dns_zone_name = "internal.hbcdev.co.in"
  api_dns_name          = "uat-eda-api"
  lb_private_ip         = module.loadbalancer.private_ip

  enable_boot_diagnostics               = false
  boot_diagnostics_mode                 = "none"
  boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

  # enable_boot_diagnostics               = true
  # boot_diagnostics_mode                 = "existing"
  # boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

  os_disk_storage_type = "Standard_LRS"
  os_disk_size_gb      = 127

  # data_disks = [
  #   {
  #     size_gb      = 127
  #     lun          = 0
  #     caching      = "ReadWrite"
  #     storage_type = "Standard_LRS"
  #   }
  # ]

  zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

  enable_backup = false

  enable_autoscale           = false
  autoscale_min_capacity     = 1
  autoscale_max_capacity     = 3
  autoscale_default_capacity = 1

  autoscale_cpu_scale_out_threshold = 70
  autoscale_cpu_scale_in_threshold  = 30

  autoscale_cooldown = "PT5M"

  enable_autoscale_notifications = false
  autoscale_notification_email   = "admin@company.com"

  depends_on = [
    module.loadbalancer,
    module.key_vault
  ]
}

# Load Balancer Module
module "loadbalancer" {
  source = "../../../modules/az-loadbalancer"

  env      = local.env
  workload = local.workload

  lb_name = "${local.env}-${local.workload}-lb" # change to "${local.env}-lb-priv" for private LB

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # LB Configuration
  sku_name         = "Standard" # Standard or Basic
  frontend_ip_type = "Private"  # Public or Private;  For Private LB: use a valid subnet output (e.g., spoke/web); update the key if your subnet naming differs.
  # subnet_id        = null                 # Empty means Public LB
  subnet_id = module.virtual_network.subnet_lookup["AzureLoadBalancer"]


  private_dns_zone_name = "internal.hbcdev.co.in"
}

# NAT Gateway Module
module "nat_app" {
  source = "../../../modules/az-nat-gateway"

  name                = "${local.env}-${local.workload}-natgw-app"
  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  enable_nat_gateway      = true
  enable_public_ip        = true
  enable_public_ip_prefix = false

  subnet_ids = {
    vmss = module.virtual_network.subnet_lookup["vmss"]
  }
}


module "static_web_app_r1" {

  source = "../../../modules/az-static-web-app"

  name                = "${local.env}-${local.workload}-swa-r1"
  location            = "eastasia"
  resource_group_name = module.rg.resource_group_name

  tags = module.rg.tags

  api_url = "https://uat-eda-api.internal.hbcdev.co.in"

  custom_domain = "uat-eda-r1.hbcdev.co.in"

  domain        = "hbcdev.co.in"
  hostname_only = "uat-eda-r1"

  key_vault_id        = module.key_vault.key_vault_id
  godaddy_secret_name = "godaddy-apikey"

  depends_on = [
    module.key_vault
  ]
}