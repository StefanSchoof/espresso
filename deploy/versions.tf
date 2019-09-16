
terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "~> 1.33"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "external" {
  version = "~> 1.2"
}
