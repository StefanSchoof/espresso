output "storage_account" {
  value = azurerm_storage_account.storage.name
}

output "function_app" {
  value = azurerm_function_app.function.name
}

output "function_app_hostname" {
  value = azurerm_function_app.function.default_hostname
}

output "azurerm_application_insights_web" {
  value     = azurerm_application_insights.web.instrumentation_key
  sensitive = true
}

output "azurerm_application_insights_node" {
  value     = azurerm_application_insights.node.instrumentation_key
  sensitive = true
}

output "static-web-url" {
  value = data.azurerm_storage_account.this.primary_web_endpoint
}

output "iot_device_connection_string" {
  value     = data.external.iot_device.result.connectionString
  sensitive = true
}
