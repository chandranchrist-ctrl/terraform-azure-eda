/* Public IP (only for Public LB) */
resource "azurerm_public_ip" "lb_public_ip" {
  count               = var.frontend_ip_type == "Public" ? 1 : 0
  name                = var.public_ip_name != "" ? var.public_ip_name : "${var.lb_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Load Balancer
resource "azurerm_lb" "lb" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_name

  frontend_ip_configuration {
    name = "${var.lb_name}-fe"

    subnet_id = var.frontend_ip_type == "Private" ? var.subnet_id : null

    public_ip_address_id = var.frontend_ip_type == "Public" && length(azurerm_public_ip.lb_public_ip) > 0 ? azurerm_public_ip.lb_public_ip[0].id : null
  }
}

# =========================
# SINGLE BACKEND POOL
# =========================
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = var.backend_address_pool_name
  loadbalancer_id = azurerm_lb.lb.id
}

# =========================
# PROBES
# =========================
resource "azurerm_lb_probe" "probes" {
  for_each = { for p in local.all_probes : p.name => p }

  name                = each.value.name
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = each.value.protocol
  port                = each.value.port
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
}

# Flatten probes (still useful)
locals {
  all_probes = flatten([
    for p in local.probes : p
  ])
}

# =========================
# LB RULES
# =========================
resource "azurerm_lb_rule" "lb_rules" {
  for_each = { for r in local.all_lb_rules : r.name => r }

  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.backend_pool.id
  ]

  probe_id = lookup(azurerm_lb_probe.probes, each.value.probe_name, null) != null ? azurerm_lb_probe.probes[each.value.probe_name].id : null

  disable_outbound_snat = true
}

# Flatten rules
locals {
  all_lb_rules = flatten([
    for r in local.lb_rules : r
  ])
}

resource "azurerm_private_dns_a_record" "lb" {
  count = var.frontend_ip_type == "Private" ? 1 : 0

  name                = var.lb_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300

  records = [
    azurerm_lb.lb.frontend_ip_configuration[0].private_ip_address
  ]
}