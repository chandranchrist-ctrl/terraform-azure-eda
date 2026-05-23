resource "azurerm_traffic_manager_profile" "traffic_manager" {

  count = var.create_traffic_manager ? 1 : 0

  name = var.traffic_manager_name

  resource_group_name = var.resource_group_name

  profile_status = "Enabled"

  traffic_routing_method = var.traffic_routing_method

  traffic_view_enabled = true

  dns_config {

    relative_name = var.dns_relative_name

    ttl = var.ttl
  }

  monitor_config {

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

data "azurerm_traffic_manager_profile" "existing" {

  count = var.create_traffic_manager ? 0 : 1

  name = var.traffic_manager_name

  resource_group_name = var.resource_group_name
}

locals {

  traffic_manager_id = var.create_traffic_manager ? azurerm_traffic_manager_profile.traffic_manager[0].id : data.azurerm_traffic_manager_profile.existing[0].id

  traffic_manager_fqdn = var.create_traffic_manager ? azurerm_traffic_manager_profile.traffic_manager[0].fqdn : data.azurerm_traffic_manager_profile.existing[0].fqdn
}

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