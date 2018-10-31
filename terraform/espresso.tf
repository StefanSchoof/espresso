# Configure the Azure Provider
provider "azurerm" {
    version =  "~> 1.15"
 }

variable "env" {
  type = "string"
  default = "test"
}

locals {
  stage = "${var.env == "production" ? "" : "${var.env}" }"
}


# Create a resource group
resource "azurerm_resource_group" "espresso" {
  name     = "espresso${local.stage}"
  location = "West Europe"
}

resource "azurerm_storage_account" "espressopi" {
  name                      = "espressopi${local.stage}"
  resource_group_name       = "${azurerm_resource_group.espresso.name}"
  location                  = "${azurerm_resource_group.espresso.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind = "StorageV2"
}

resource "azurerm_iothub" "espresso" {
  name                = "espresso${local.stage}"
  resource_group_name = "${azurerm_resource_group.espresso.name}"
  location            = "${azurerm_resource_group.espresso.location}"
  sku {
    name = "${var.env == "production" ? "F1" : "S1"}"
    tier = "${var.env == "production" ? "Free" : "Standard"}"
    capacity = "1"
  }
}

resource "azurerm_app_service_plan" "WestEuropePlan" {
  name                = "WestEuropePlan"
  location            = "${azurerm_resource_group.espresso.location}"
  resource_group_name = "${azurerm_resource_group.espresso.name}"
  kind = "functionapp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "espressoPi" {
  name                      = "espressoPi${local.stage}"
  location                  = "${azurerm_resource_group.espresso.location}"
  resource_group_name       = "${azurerm_resource_group.espresso.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.WestEuropePlan.id}"
  storage_connection_string = "${azurerm_storage_account.espressopi.primary_connection_string}"
  app_settings {
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
}

resource "azurerm_key_vault" "keyvault" {
  name                        = "espresso${local.stage}Vault"
  location                    = "${azurerm_resource_group.espresso.location}"
  resource_group_name         = "${azurerm_resource_group.espresso.name}"
  tenant_id                   = "${var.aad_tenant_id}"

  sku {
    name = "standard"
  }
}

resource "azurerm_application_insights" "node" {
  name                = "espresso${local.stage}-node"
  location            = "${azurerm_resource_group.espresso.location}"
  resource_group_name = "${azurerm_resource_group.espresso.name}"
  application_type    = "other" # "Node.JS" # See https://github.com/terraform-providers/terraform-provider-azurerm/issues/2179
}

resource "azurerm_application_insights" "web" {
  name                = "espresso${local.stage}-web"
  location            = "${azurerm_resource_group.espresso.location}"
  resource_group_name = "${azurerm_resource_group.espresso.name}"
  application_type    = "web"
}

resource "azurerm_application_insights" "function" {
  name                = "espressoPi${local.stage}"
  location            = "${azurerm_resource_group.espresso.location}"
  resource_group_name = "${azurerm_resource_group.espresso.name}"
  application_type    = "web"
}

output "resource_group" {
  value = "${azurerm_resource_group.espresso.name}"
}

output "storage_account" {
  value = "${azurerm_storage_account.espressopi.name}"
}

output "azurerm_iothub" {
  value = "${azurerm_iothub.espresso.name}"
}