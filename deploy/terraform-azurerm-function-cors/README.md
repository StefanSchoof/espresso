# terraform-azurerm-static-website

A module to add allowed cors origins. This is a workaround until <https://github.com/terraform-providers/terraform-provider-azurerm/issues/1374> is resolved

## Limitations

1. You need a valid session in the Azure CLI (even when you Authenticating terrafrom not with the Azure CLI)
2. A destroy does not remove the origin. You must remove the by other ways.

## Example

```terraform
resource "azurerm_resource_group" "testrg" {
  name     = "resourceGroupName"
  location = "westus"
}

resource "azurerm_storage_account" "testsa" {
  name                = "storageaccountname"
  resource_group_name = azurerm_resource_group.testrg.name
  location            = "westus"

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "GRS"
}
```
