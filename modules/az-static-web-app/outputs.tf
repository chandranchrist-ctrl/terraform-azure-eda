output "static_web_app_id" {
  value = azurerm_static_web_app.static_web_app.id
}

output "default_host_name" {
  value = azurerm_static_web_app.static_web_app.default_host_name
}

output "principal_id" {
  value = azurerm_static_web_app.static_web_app.identity[0].principal_id
}

output "deployment_token" {
  value     = azurerm_static_web_app.static_web_app.api_key
  sensitive = true
}