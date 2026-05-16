output "bastion_id" {
  value = var.enable_bastion ? azurerm_bastion_host.bastion[0].id : null
}

output "bastion_fqdn" {
  value = var.enable_bastion ? azurerm_bastion_host.bastion[0].dns_name : null
}

output "public_ip_id" {
  value = var.enable_bastion ? azurerm_public_ip.bastion_pip[0].ip_address : null
}