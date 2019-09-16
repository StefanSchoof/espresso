#!/bin/bash
set -e
. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}

echo "write to keyvault"
deviceConnectionString="$(terraform output iot_device_connection_string)"
writeDevopsVar DeviceConnectionString "$deviceConnectionString" true true
nodeInstrumentationKey="$(terraform output azurerm_application_insights_node)"
writeDevopsVar NodeInstrumentationKey "$nodeInstrumentationKey" true true
websiteUrl=$(terraform output static-web-url)
