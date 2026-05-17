output "nat_gateway_id" {
  value = var.enable_nat_gateway ? azurerm_nat_gateway.nat_gateway[0].id : null
}

output "nat_gateway_name" {
  value = var.enable_nat_gateway ? azurerm_nat_gateway.nat_gateway[0].name : null
}

output "public_ip" {
  value = var.enable_nat_gateway && var.enable_public_ip ? azurerm_public_ip.nat_pip[0].ip_address : null
}

output "public_ip_id" {
  value = var.enable_nat_gateway && var.enable_public_ip ? azurerm_public_ip.nat_pip[0].id : null
}