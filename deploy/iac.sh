#!/bin/bash
set -e
. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}

function applyTerraform {
  terraform init -backend-config=/temp/backend.conf -input=false
  terraform plan -lock-timeout=50m -out=tfplan -input=false
  terraform apply -lock-timeout=50m -input=false tfplan
}

function ensureStaticWeb {
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
}

function ensureIotDevice {
  # currently not supported in terraform, see https://github.com/terraform-providers/terraform-provider-azurerm/issues/1712
  iothub=$(terraform output iothub)
  deviceId="espressoPi"
  az extension add --name azure-cli-iot-ext
  if ! az iot hub device-identity show --hub-name $iothub --device-id $deviceId &> /dev/null
  then
    echo "Add $deviceId to iot hub"
    az iot hub device-identity create --hub-name $iothub --device-id $deviceId > /dev/null
  fi
}

function ensureFunctionsCors {
  # currently not supported in terraform, see https://github.com/terraform-providers/terraform-provider-azurerm/issues/1374
  function_app=$(terraform output function_app)
  if ! az functionapp cors show -g $resource_group -n $function_app --query allowedOrigins --out tsv | grep "${websiteUrl%/}" --quiet
  then
    echo "add cors"
    az functionapp cors add -g $resource_group -n $function_app --allowed-origins ${websiteUrl%/}
  fi
}

function writeKeyVault
{
  echo "write to keyvault"
  deviceConnectionString="$(az iot hub device-identity show-connection-string --hub-name $iothub --device-id $deviceId --output tsv)"
  writeDevopsVar DeviceConnectionString "$deviceConnectionString" true
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name 'DeviceConnectionString' --value "$deviceConnectionString"
  nodeInstrumentationKey="$(terraform output azurerm_application_insights_node)"
  writeDevopsVar NodeInstrumentationKey "$nodeInstrumentationKey" true
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name NodeInstrumentationKey --value "$nodeInstrumentationKey"
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name WebsiteUrl --value "$websiteUrl"
}

applyTerraform
ensureStaticWeb
ensureIotDevice
ensureFunctionsCors

if [ -n "$KEYVAULTNAME" ]
then
  writeKeyVault
fi
