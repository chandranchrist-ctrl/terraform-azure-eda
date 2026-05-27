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

    # Enables full VNet routing for secure outbound connectivity
    vnet_route_all_enabled = true

    # Dynamically allows configured IP ranges for controlled access
    dynamic "ip_restriction" {
      for_each = var.allowed_ip_rules

      content {
        name       = "Allow-${replace(ip_restriction.value, "/", "-")}"
        priority   = 100 + index(var.allowed_ip_rules, ip_restriction.value)
        action     = "Allow"
        ip_address = ip_restriction.value
      }
    }

    # Denies all other traffic by default (secure-by-default model)
    ip_restriction {
      name       = "Deny-All"
      priority   = 500
      action     = "Deny"
      ip_address = "0.0.0.0/0"
    }
  }

  # App settings define runtime configuration for the Function App including storage, queue trigger, SQL connection, and Logic App integration
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"

    # Azure Storage used for Function runtime state and triggers
    AzureWebJobsStorage = var.storage_connection_string

    # Queue name used for event-driven processing
    QUEUE_NAME = var.queue_name

    # Callback endpoint for Logic App orchestration
    LOGIC_APP_CALLBACK_URL = var.logic_app_callback_url

    # SQL connection string for order processing and persistence
    SQL_CONNECTION_STRING = var.sql_connection_string

    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  tags = var.tags
}

# Integrates Function App with Virtual Network for private subnet access
resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  app_service_id = azurerm_windows_function_app.function_app.id
  subnet_id      = var.subnet_id
}