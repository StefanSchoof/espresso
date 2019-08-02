#!/bin/bash -e

function writeDevopsVar {
  options=""
  if [ $3 ]
  then
    options=";issecret=true"
  fi
  if [ $4 ]
  then
    options="$options;isOutput=true"
  fi
  echo "##vso[task.setvariable variable=$1$options]$2"
}

function setTerraformVars {
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
}

function initTerraform {
  setTerraformVars
  terraform init -lock-timeout=50m -input=false
}

