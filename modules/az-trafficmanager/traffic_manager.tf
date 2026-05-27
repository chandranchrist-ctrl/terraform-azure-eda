# Creates or references Azure Traffic Manager profile for global routing, endpoint health monitoring, and DR failover
resource "azurerm_traffic_manager_profile" "traffic_manager" {

  count = var.create_traffic_manager ? 1 : 0

  name = var.traffic_manager_name

  resource_group_name = var.resource_group_name

  profile_status = "Enabled"

  # Defines routing strategy (Priority, Weighted, Performance, Geographic, etc.)
  traffic_routing_method = var.traffic_routing_method

  # Enables Traffic View analytics for endpoint traffic insights
  traffic_view_enabled = true

  dns_config {

    relative_name = var.dns_relative_name

    ttl = var.ttl
  }

  monitor_config {

    # Health probe configuration used to detect endpoint availability
    protocol = var.monitor_protocol

    port = var.monitor_port

    path = var.monitor_path

    interval_in_seconds = 30

    timeout_in_seconds = 10

    tolerated_number_of_failures = 3
  }

  tags = var.tags

  depends_on = [
    var.validation_dependency
  ]
}

# References existing Traffic Manager profile when onboarding DR environment
data "azurerm_traffic_manager_profile" "existing" {

  count = var.create_traffic_manager ? 0 : 1

  name = var.traffic_manager_name

  resource_group_name = var.resource_group_name
}

locals {

  # Selects either newly created or existing Traffic Manager profile ID
  traffic_manager_id = var.create_traffic_manager ? azurerm_traffic_manager_profile.traffic_manager[0].id : data.azurerm_traffic_manager_profile.existing[0].id

  # Selects Traffic Manager FQDN for DNS integration
  traffic_manager_fqdn = var.create_traffic_manager ? azurerm_traffic_manager_profile.traffic_manager[0].fqdn : data.azurerm_traffic_manager_profile.existing[0].fqdn
}

# Registers primary Static Web App endpoint in Traffic Manager profile
resource "azurerm_traffic_manager_external_endpoint" "primary" {

  count = var.create_primary_endpoint ? 1 : 0

  name = var.primary_endpoint_name

  profile_id = local.traffic_manager_id

  target = var.primary_target

  endpoint_location = var.primary_endpoint_location

  priority = var.primary_swa_priority

  enabled = var.primary_swa_enabled

  depends_on = [
    azurerm_traffic_manager_profile.traffic_manager
  ]
}

# Registers DR Static Web App endpoint for failover routing in Traffic Manager
resource "azurerm_traffic_manager_external_endpoint" "dr" {

  count = var.enable_dr ? 1 : 0

  name = var.dr_endpoint_name

  profile_id = local.traffic_manager_id

  target = var.dr_target

  endpoint_location = var.dr_endpoint_location

  priority = var.dr_swa_priority

  enabled = var.dr_swa_enabled

  depends_on = [
    data.azurerm_traffic_manager_profile.existing
  ]
}