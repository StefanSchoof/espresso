# Configure the Azure Provider
provider "azurerm" {
    version =  "~> 1.15"
}

locals {
  stage = "${terraform.workspace == "prod" ? "" : "${terraform.workspace}" }"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "group" {
  name     = "espresso${local.stage}"
  location = "West Europe"
}

resource "azurerm_storage_account" "storage" {
  name                      = "espressopi${local.stage}"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  location                  = "${azurerm_resource_group.group.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind = "StorageV2"
  lifecycle  {
    prevent_destroy = true
  }
}

resource "azurerm_iothub" "iothub" {
  name                = "espresso${local.stage}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  location            = "${azurerm_resource_group.group.location}"
  sku {
    name = "${terraform.workspace == "prod" ? "F1" : "S1"}"
    tier = "${terraform.workspace == "prod" ? "Free" : "Standard"}"
    capacity = "1"
  }
}

resource "azurerm_app_service_plan" "WestEuropePlan" {
  name                = "WestEuropePlan"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  kind = "functionapp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function" {
  name                      = "espressoPi${local.stage}"
  location                  = "${azurerm_resource_group.group.location}"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.WestEuropePlan.id}"
  storage_connection_string = "${azurerm_storage_account.storage.primary_connection_string}"
  identity {
    type = "SystemAssigned"
  }

  app_settings {
    WEBSITE_RUN_FROM_PACKAGE = "1"
    WEBSITE_NODE_DEFAULT_VERSION = "8.11.1"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.function.instrumentation_key}"
    KEYVAULT_URI = "${azurerm_key_vault.keyvault.vault_uri}"
  }
  lifecycle {
    ignore_changes = [
      "app_settings.%",
      "app_settings.WEBSITE_RUN_FROM_ZIP", # Done by the function depolyment
    ]
  }
  version = "~2"
}

resource "azurerm_key_vault" "keyvault" {
  name                        = "espresso${local.stage}Vault"
  location                    = "${azurerm_resource_group.group.location}"
  resource_group_name         = "${azurerm_resource_group.group.name}"
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
}

resource "azurerm_key_vault_access_policy" "app" {
   vault_name = "${azurerm_key_vault.keyvault.name}"
   resource_group_name = "${azurerm_key_vault.keyvault.resource_group_name}"

    tenant_id = "${azurerm_function_app.function.identity.0.tenant_id}"
    object_id = "${azurerm_function_app.function.identity.0.principal_id}"

    key_permissions = [
    ]

    secret_permissions = [
      "get",
    ]
  }

resource "azurerm_key_vault_access_policy" "service" {
    vault_name = "${azurerm_key_vault.keyvault.name}"
    resource_group_name = "${azurerm_key_vault.keyvault.resource_group_name}"

    tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

    key_permissions = [
    ]

    secret_permissions = [
      "get",
      "set",
      "list",
    ]
  }

resource "azurerm_key_vault_secret" "iotHubConnectionString" {
  name      = "iotHubConnectionString"
  value     = "HostName=${azurerm_iothub.iothub.hostname};SharedAccessKeyName=${azurerm_iothub.iothub.shared_access_policy.0.key_name};SharedAccessKey=${azurerm_iothub.iothub.shared_access_policy.0.primary_key}"
  vault_uri = "${azurerm_key_vault.keyvault.vault_uri}"
}

resource "azurerm_application_insights" "node" {
  name                = "espresso${local.stage}-node"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "other" # "Node.JS" # See https://github.com/terraform-providers/terraform-provider-azurerm/issues/2179
}

resource "azurerm_application_insights" "web" {
  name                = "espresso${local.stage}-web"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "web"
}

resource "azurerm_application_insights" "function" {
  name                = "espressoPi${local.stage}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "web"
}
