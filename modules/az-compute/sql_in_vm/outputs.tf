output "vm_names" {
  value = local.vm_names
}

output "vm_ids" {
  value = {
    for k, v in azurerm_windows_virtual_machine.vm :
    k => v.id
  }
}

output "private_ips" {
  value = {
    for k, v in azurerm_network_interface.nic :
    k => v.private_ip_address
  }
}

output "public_ips" {
  value = var.enable_public_ip ? {
    for k, v in azurerm_public_ip.pip :
    k => v.ip_address
  } : {}
}

output "public_ip_ids" {
  value = {
    for k, v in azurerm_public_ip.pip : k => v.id
  }
}

output "private_ip" {
  value = [
    for nic in azurerm_network_interface.nic :
    nic.private_ip_address
  ]
}

