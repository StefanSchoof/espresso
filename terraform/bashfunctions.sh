#!/bin/bash -e

function terraform {
  docker run \
    --env-file ${AGENT_TEMPDIRECTORY:-.}/azurerm.env \
    -e TF_IN_AUTOMATION=true \
    -e TF_WORKSPACE \
    -v $(pwd):/app/ \
    -v ${AGENT_TEMPDIRECTORY:-$PWD}:/temp/ \
    -w /app/ \
    hashicorp/terraform $@
}
