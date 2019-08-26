#!/bin/bash
set -e
. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}

function writeKeyVault
{
  echo "write to keyvault"
  deviceConnectionString="$(az iot hub device-identity show-connection-string --hub-name $iothub --device-id $deviceId --output tsv)"
  writeDevopsVar DeviceConnectionString "$deviceConnectionString" true
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name 'DeviceConnectionString' --value "$deviceConnectionString"
  nodeInstrumentationKey="$(terraform output azurerm_application_insights_node)"
  writeDevopsVar NodeInstrumentationKey "$nodeInstrumentationKey" true
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name NodeInstrumentationKey --value "$nodeInstrumentationKey"
  websiteUrl=$(terraform output static-web-url)
  az keyvault secret set --vault-name "$KEYVAULTNAME" --name WebsiteUrl --value "$websiteUrl"
}

if [ -n "$KEYVAULTNAME" ]
then
  writeKeyVault
fi
