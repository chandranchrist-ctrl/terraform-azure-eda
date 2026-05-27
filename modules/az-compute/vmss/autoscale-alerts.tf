# Creates CPU-based VMSS scale-out alert and triggers notification action group
resource "azurerm_monitor_metric_alert" "vmss_scale_out" {
  count = var.enable_autoscale_notifications ? 1 : 0

  name                = "${var.vmss_name}-scaleout-alert"
  resource_group_name = var.resource_group_name

  scopes = [
    azurerm_windows_virtual_machine_scale_set.vmss.id
  ]

  description = "VMSS scale out alert"

  severity    = 2
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.autoscale_cpu_scale_out_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.vmss[0].id
  }

  tags = var.tags
}

# Creates CPU-based VMSS scale-in alert and triggers notification action group
resource "azurerm_monitor_metric_alert" "vmss_scale_in" {
  count = var.enable_autoscale_notifications ? 1 : 0

  name                = "${var.vmss_name}-scalein-alert"
  resource_group_name = var.resource_group_name

  scopes = [
    azurerm_windows_virtual_machine_scale_set.vmss.id
  ]

  description = "VMSS scale in alert"

  severity    = 2
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.autoscale_cpu_scale_in_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.vmss[0].id
  }

  tags = var.tags
}