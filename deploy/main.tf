resource "random_pet" "func" {
}

data "azurerm_client_config" "current" {
}


resource "azurerm_resource_group" "group" {
  name     = "espresso${var.stage}"
  location = "West Europe"
}

resource "azurerm_storage_account" "storage" {
  name                     = "espressopi${var.stage}"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  lifecycle {
    prevent_destroy = true
  }
}

resource "null_resource" "static-website" {
  triggers = {
    account = azurerm_storage_account.storage.name
  }
  provisioner "local-exec" {
    command = "az account show || az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID && az storage blob service-properties update --account-name ${azurerm_storage_account.storage.name} --static-website true --index-document index.html --404-document 404.html"
  }
}

data "azurerm_storage_account" "this" {
  name                = azurerm_storage_account.storage.name
  resource_group_name = azurerm_resource_group.group.name

  depends_on = ["null_resource.static-website"]
}

resource "azurerm_iothub" "iothub" {
  name                = "espresso${var.stage}"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku {
    name     = var.stage == "" ? "F1" : "S1"
    tier     = var.stage == "" ? "Free" : "Standard"
    capacity = "1"
  }
}

resource "null_resource" "iot-device" {
  triggers = {
    account = azurerm_iothub.iothub.name
  }
  provisioner "local-exec" {
    command = "az account show || az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID && az extension add --name azure-cli-iot-ext && az iot hub device-identity create --hub-name ${azurerm_iothub.iothub.name} --device-id espressoPi > /dev/null"
  }
}

data "external" "iot_device" {
  program    = ["sh", "iotdeviceconnection.sh", azurerm_iothub.iothub.name]
  depends_on = [null_resource.iot-device]
}

resource "azurerm_app_service_plan" "WestEuropePlan" {
  name                = "WestEuropePlan"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  kind                = "functionapp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function" {
  # for an unkown reason sometime the func has no code. changing the name with a `terraform taint random_pet.func` will generate a new name
  name                      = "espressofunc${var.stage == "" ? "" : "-${random_pet.func.id}-"}${var.stage}"
  location                  = azurerm_resource_group.group.location
  resource_group_name       = azurerm_resource_group.group.name
  app_service_plan_id       = azurerm_app_service_plan.WestEuropePlan.id
  storage_connection_string = azurerm_storage_account.storage.primary_connection_string
  identity {
    type = "SystemAssigned"
  }

  site_config {
    cors {
      allowed_origins = [substr(data.azurerm_storage_account.this.primary_web_endpoint, 0, length(data.azurerm_storage_account.this.primary_web_endpoint) - 1)]
    }
    http2_enabled = true
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_RUN_FROM_PACKAGE       = "1"
    WEBSITE_NODE_DEFAULT_VERSION   = "~12"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.function.instrumentation_key
    IOTHUB_CONNECTION_STRING       = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.iotHubConnectionString.id})"
  }
  version = "~3"
}

resource "azurerm_key_vault" "keyvault" {
  name                = "espresso${var.stage}Vault"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = azurerm_function_app.function.identity[0].tenant_id
  object_id = azurerm_function_app.function.identity[0].principal_id

  key_permissions = [
  ]

  secret_permissions = [
    "get",
  ]
}

resource "azurerm_key_vault_access_policy" "service" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = var.object_id == "" ? data.azurerm_client_config.current.service_principal_object_id : var.object_id

  key_permissions = [
  ]

  secret_permissions = [
    "get",
    "set",
    "list",
    "delete",
  ]
}

resource "azurerm_key_vault_secret" "iotHubConnectionString" {
  name         = "iotHubConnectionString"
  value        = "HostName=${azurerm_iothub.iothub.hostname};SharedAccessKeyName=${azurerm_iothub.iothub.shared_access_policy[0].key_name};SharedAccessKey=${azurerm_iothub.iothub.shared_access_policy[0].primary_key}"
  key_vault_id = azurerm_key_vault.keyvault.id

  depends_on = [azurerm_key_vault_access_policy.service]
}

resource "azurerm_application_insights" "node" {
  name                = "espresso${var.stage}-node"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "Node.JS"
}

resource "azurerm_application_insights" "web" {
  name                = "espresso${var.stage}-web"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
}

resource "azurerm_application_insights" "function" {
  name                = "espressoPi${var.stage}"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
}

