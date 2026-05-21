output "logic_app_id" {
  value = azurerm_logic_app_workflow.logic_app.id
}

output "logic_app_name" {
  value = azurerm_logic_app_workflow.logic_app.name
}

output "callback_url" {
  value     = azurerm_logic_app_trigger_http_request.order_trigger.callback_url
  sensitive = true
}

