#!/bin/bash -e
. bashfunctions.sh

terraform init -backend-config=backend.conf -input=false
terraform workspace select test
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan
resource_group=$(terraform output resource_group)
storage_account=$(terraform output storage_account)

# currently not supported in terraform, see https://github.com/terraform-providers/terraform-provider-azurerm/issues/1903
az extension add --name storage-preview
if [ "$(az storage blob service-properties show --account-name $storage_account --query 'staticWebsite.enabled')" = "false" ];
then
    echo "activate static web"
    az storage blob service-properties update --account-name $storage_account --static-website --index-document index.html > /dev/null
fi
websiteUrl=$(az storage account show -n $storage_account -g $resource_group --query "primaryEndpoints.web" --output tsv)
echo "websiteUrl: $websiteUrl"

# currently not supported in terraform, see https://github.com/terraform-providers/terraform-provider-azurerm/issues/1712
iothub=$(terraform output iothub)
deviceId="espressoPi"
az extension add --name azure-cli-iot-ext
if ! az iot hub device-identity show --hub-name $iothub --device-id $deviceId &> /dev/null
then
    echo "Add $deviceId to iot hub"
    az iot hub device-identity create --hub-name $iothub --device-id $deviceId > /dev/null
fi
deviceConnectionString=$(az iot hub device-identity show-connection-string --hub-name $iothub --device-id $deviceId --output tsv)

# currently not supported in terraform, see https://github.com/terraform-providers/terraform-provider-azurerm/issues/1374
function_app=$(terraform output function_app)
az functionapp cors add -g $resource_group -n $function_app --allowed-origins ${websiteUrl%/}
