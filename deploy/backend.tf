terraform {
  backend "azurerm" {
    storage_account_name = "espressotfstate"
    container_name = "tfstate"
    key = "terraform.tfstate"
  }
}
