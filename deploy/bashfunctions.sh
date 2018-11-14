#!/bin/bash -e

function terraform {
  docker run \
    --rm \
    --env-file ${AGENT_TEMPDIRECTORY:-.}/azurerm.env \
    -e TF_IN_AUTOMATION=true \
    -e TF_WORKSPACE \
    -v $(pwd):/app/ \
    -v ${AGENT_TEMPDIRECTORY:-$PWD}:/temp/ \
    -w /app/ \
    hashicorp/terraform $@
}

function writeDevopsVar {
  secret=""
  if [ $3 ]
  then
    secret=";issecret=true"
  fi
  echo "##vso[task.setvariable variable=$1$secret]$2"
}
