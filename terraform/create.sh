#!/bin/bash -e
terraform apply
resource_group=$(terraform output resource_group)
storage_account=$(terraform output storage_account)
az extension add --name storage-preview
if [ "$(az storage blob service-properties show --account-name $storage_account --query 'staticWebsite.enabled')" = "false" ];
then
    az storage blob service-properties update --account-name $storage_account --static-website --index-document index.html
fi
websiteUrl=$(az storage account show -n $storage_account -g $resource_group --query "primaryEndpoints.web" --output tsv)

azurerm_iothub=$(terraform output azurerm_iothub)
deviceId="espressoPi"
az extension add --name azure-cli-iot-ext
if ! az iot hub device-identity show --hub-name $azurerm_iothub --device-id $deviceId
then
    az iot hub device-identity create --hub-name $azurerm_iothub --device-id $deviceId
fi
deviceConnectionString=$(az iot hub device-identity show-connection-string --hub-name $azurerm_iothub --device-id $deviceId --output tsv)
serviceConnectionString=$(az iot hub show-connection-string --hub-name $azurerm_iothub --output tsv)