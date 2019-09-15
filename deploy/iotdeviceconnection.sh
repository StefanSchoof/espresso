#!/bin/sh
if ! az account show > /dev/null
then
  az login --service-principal -u $ARM_CLIENT_ID -p  $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null
fi
if ! az iot hub device-identity show-connection-string --hub-name $1 --device-id espressoPi 2>/dev/null
then
  echo '{"connectionString":""}'
fi
