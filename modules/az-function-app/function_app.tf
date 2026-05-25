resource "azurerm_windows_function_app" "function_app" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id = var.service_plan_id

  storage_account_name          = var.storage_account_name
  storage_uses_managed_identity = true

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true

    application_stack {
      dotnet_version              = "v10.0"
      use_dotnet_isolated_runtime = true
    }

    vnet_route_all_enabled = true

    dynamic "ip_restriction" {
      for_each = var.allowed_ip_rules

      content {
        name       = "Allow-${replace(ip_restriction.value, "/", "-")}"
        priority   = 100 + index(var.allowed_ip_rules, ip_restriction.value)
        action     = "Allow"
        ip_address = ip_restriction.value
      }
    }

    ip_restriction {
      name       = "Deny-All"
      priority   = 500
      action     = "Deny"
      ip_address = "0.0.0.0/0"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"

    AzureWebJobsStorage = var.storage_connection_string

    QUEUE_NAME = var.queue_name

    LOGIC_APP_CALLBACK_URL = var.logic_app_callback_url

    SQL_CONNECTION_STRING = var.sql_connection_string

    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  tags = var.tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  app_service_id = azurerm_windows_function_app.function_app.id
  subnet_id      = var.subnet_id
}