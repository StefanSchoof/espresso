#!/bin/bash
set -e
. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}

function applyTerraform {
  initTerraform
  terraform plan -lock-timeout=50m -out=tfplan -input=false
  terraform apply -lock-timeout=50m -input=false tfplan
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
ensureIotDevice
ensureFunctionsCors

if [ -n "$KEYVAULTNAME" ]
then
  writeKeyVault
fi
