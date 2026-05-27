# Creates Azure Monitor action group for VMSS autoscale email notifications
resource "azurerm_monitor_action_group" "vmss" {
  count = var.enable_autoscale_notifications ? 1 : 0

  name                = "${var.vmss_name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "vmssag"

  email_receiver {
    name          = "admin"
    email_address = var.autoscale_notification_email
  }

  tags = var.tags
}