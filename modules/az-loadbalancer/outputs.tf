output "lb_id" {
  value = azurerm_lb.lb.id
}

output "frontend_ip_name" {
  value = "${var.lb_name}-fe"
}

output "lb_name" {
  value = azurerm_lb.lb.name
}

output "public_ip_address" {
  value = var.frontend_ip_type == "Public" ? azurerm_public_ip.lb_public_ip[0].ip_address : ""
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}

output "private_ip" {
  value = var.frontend_ip_type == "Private" ? azurerm_lb.lb.frontend_ip_configuration[0].private_ip_address : null
}
