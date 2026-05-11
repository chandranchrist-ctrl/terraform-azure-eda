# Network - Workload Subnet Filter
locals {
  workload_subnets = {
    for k, v in local.subnet_map :
    k => v
    if try(v.tags.type, "infra") == "workload"
  }
}


# Create NSG per workload subnet
resource "azurerm_network_security_group" "nsg" {
  for_each = local.workload_subnets

  name = "${var.env}-${var.workload}-${each.value.subnet_key}-nsg"

  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


# Associate NSG to Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = local.workload_subnets

  subnet_id = azurerm_subnet.subnet[each.key].id

  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}


# Flatten NSG Rules
locals {
  nsg_rules_flat = merge([
    for subnet_key, rules in local.nsg_rules : {
      for rule in rules :
      "${subnet_key}-${rule.name}" => {
        subnet_key = subnet_key
        rule       = rule
      }
    }
  ]...)
}


# NSG Rules
resource "azurerm_network_security_rule" "nsg_rule" {
  for_each = local.nsg_rules_flat

  name      = each.value.rule.name
  priority  = each.value.rule.priority
  direction = each.value.rule.direction
  access    = each.value.rule.access
  protocol  = each.value.rule.protocol

  source_port_range = each.value.rule.source_port_range

  destination_port_range = (
    can(each.value.rule.destination_port_range) &&
    !can(each.value.rule.destination_port_ranges)
    ? each.value.rule.destination_port_range
    : null
  )

  destination_port_ranges = (
    can(each.value.rule.destination_port_ranges)
    ? each.value.rule.destination_port_ranges
    : null
  )

  # CIDR OR Service Tag Support
  source_address_prefix      = try(each.value.rule.source_address_prefix, null)
  destination_address_prefix = try(each.value.rule.destination_address_prefix, null)

  source_address_prefixes      = try(each.value.rule.source_address_prefixes, null)
  destination_address_prefixes = try(each.value.rule.destination_address_prefixes, null)


  # ASG Support (Source)
  source_application_security_group_ids = (
    try(each.value.rule.source_asg, null) != null && each.value.rule.source_asg != ""
    && contains(keys(var.asg_map), each.value.rule.source_asg)
    ? [var.asg_map[each.value.rule.source_asg]]
    : null
  )


  # ASG Support (Destination)
  destination_application_security_group_ids = (
    try(each.value.rule.dest_asg, null) != null && each.value.rule.dest_asg != ""
    && contains(keys(var.asg_map), each.value.rule.dest_asg)
    ? [var.asg_map[each.value.rule.dest_asg]]
    : null
  )


  # Metadata
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_key].name
}


/* =========================================================
APPLICATION SECURITY GROUP (ASG) OVERVIEW

ASG is used to group VM NICs logically (not subnets).

NSG rules use ASG instead of IPs to allow secure communication between application tiers.

Example flow:
  Web ASG  → App ASG (port 8080)
  App ASG  → DB ASG  (port 1433)

Benefits:
  - No dependency on CIDR ranges
  - VM scaling does not require NSG changes
  - Centralized security rule management
========================================================= */