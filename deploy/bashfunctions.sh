#!/bin/bash -e

function writeDevopsVar {
  secret=""
  if [ $3 ]
  then
    secret=";issecret=true"
  fi
  echo "##vso[task.setvariable variable=$1$secret]$2"
}

function initTerraform {
  # taking the vars from the azure Devops task
  export ARM_CLIENT_ID="$servicePrincipalId"
  export ARM_CLIENT_SECRET="$servicePrincipalKey"
  export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
  export ARM_TENANT_ID="$(az account show --query tenantId --output tsv)" # after task is updated to 1.152.3 use "$tenantId"
  export TF_IN_AUTOMATION=true
  if [[ -z $servicePrincipalId ]]
  then
    export TF_VAR_object_id=$(az ad signed-in-user show --query objectId --output tsv)
  fi
  terraform init -lock-timeout=50m -input=false
}
