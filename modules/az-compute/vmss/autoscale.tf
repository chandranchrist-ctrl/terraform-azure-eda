# Configures automatic VMSS scaling based on CPU utilization thresholds
resource "azurerm_monitor_autoscale_setting" "vmss" {
  count = var.enable_autoscale ? 1 : 0

  name                = "${var.vmss_name}-autoscale"
  location            = var.location
  resource_group_name = var.resource_group_name

  target_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      minimum = var.autoscale_min_capacity
      maximum = var.autoscale_max_capacity
      default = var.autoscale_default_capacity
    }

    # Scale-out rule when CPU usage exceeds threshold
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id

        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"

        operator  = "GreaterThan"
        threshold = var.autoscale_cpu_scale_out_threshold
      }

      # Adds one VMSS instance when CPU usage stays above configured threshold
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.autoscale_cooldown
      }
    }

    # Scale-in rule when CPU usage drops below threshold
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id

        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"

        operator  = "LessThan"
        threshold = var.autoscale_cpu_scale_in_threshold
      }

      # Removes one VMSS instance when CPU usage stays below configured threshold
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.autoscale_cooldown
      }
    }
  }

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss
  ]
}