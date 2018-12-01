output "resource_group" {
  value = "${azurerm_resource_group.group.name}"
}

output "storage_account" {
  value = "${azurerm_storage_account.storage.name}"
}

output "iothub" {
  value = "${azurerm_iothub.iothub.name}"
}

output "function_app" {
  value = "${azurerm_function_app.function.name}"
}

output "function_app_hostname" {
  value = "${azurerm_function_app.function.default_hostname}"
}

output "azurerm_application_insights_web" {
  value = "${azurerm_application_insights.web.instrumentation_key}"
  sensitive = true
}

output "azurerm_application_insights_node" {
  value = "${azurerm_application_insights.node.instrumentation_key}"
  sensitive = true
}
