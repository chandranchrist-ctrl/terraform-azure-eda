locals {
  invalid_prefix_config = var.enable_public_ip_prefix && var.public_ip_prefix_id == null
}

resource "null_resource" "validate_nat" {
  count = local.invalid_prefix_config ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: public_ip_prefix_id is required when prefix is enabled' && exit 1"
  }
}

resource "azurerm_public_ip" "nat_pip" {
  count = var.enable_nat_gateway && var.enable_public_ip ? 1 : 0

  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "pip_assoc" {
  count = var.enable_nat_gateway && var.enable_public_ip ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_address_id = azurerm_public_ip.nat_pip[0].id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "prefix_assoc" {
  count = var.enable_nat_gateway && var.enable_public_ip_prefix ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_prefix_id = var.public_ip_prefix_id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_assoc" {
  for_each = var.enable_nat_gateway ? var.subnet_ids : {}

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
}

resource "azurerm_nat_gateway" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = var.tags
}