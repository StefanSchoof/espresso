#!/bin/sh
set -e
if ! az account show > /dev/null 2>&1
then
  az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null
fi
az iot hub device-identity show-connection-string --hub-name $1 --device-id espressoPi
