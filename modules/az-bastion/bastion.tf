# Network - Bastion Public IP
resource "azurerm_public_ip" "bastion_pip" {

  count = var.enable_bastion ? 1 : 0

  name                = "${var.env}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

# Network Security - Bastion Host
resource "azurerm_bastion_host" "bastion" {

  count = var.enable_bastion ? 1 : 0

  name                = "${var.env}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku = var.sku

  tunneling_enabled  = var.tunneling_enabled
  ip_connect_enabled = var.ip_connect_enabled
  copy_paste_enabled = var.copy_paste_enabled
  file_copy_enabled  = var.file_copy_enabled

  zones = var.zones

  kerberos_enabled = var.kerberos_enabled

  ip_configuration {
    name                 = "${var.env}-bastion-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip[count.index].id
  }
}