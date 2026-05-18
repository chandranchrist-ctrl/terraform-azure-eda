output "function_app_name" {
  value = azurerm_windows_function_app.function_app.name
}

output "function_app_id" {
  value = azurerm_windows_function_app.function_app.id
}

output "default_hostname" {
  value = azurerm_windows_function_app.function_app.default_hostname
}