resource "azurerm_private_dns_a_record" "uat_eda_api" {
  count = var.enable_dns_record ? 1 : 0

  name                = var.api_dns_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300

  records = [
    var.lb_private_ip
  ]
}