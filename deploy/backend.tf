terraform {
  backend "azurerm" {
    resource_group_name  = "espresso-tfstate"
    storage_account_name = "espressotfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

