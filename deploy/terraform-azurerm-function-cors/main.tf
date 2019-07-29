resource "null_resource" "function_cors" {
  triggers = {
    allowed_origins     = join(",", var.allowed_origins)
    resource_group_name = var.resource_group_name
    function_app_name   = var.function_app_name
  }

  provisioner "local-exec" {
    command = "az functionapp cors add --resource-group ${var.resource_group_name} --name ${var.function_app_name} --allowed-origins ${join(",", var.allowed_origins)}"
  }
}
