#!/bin/bash -e
function terraform {
  docker run --env-file azurerm.env -e TF_IN_AUTOMATION=true -v $(pwd):/app/ -w /app/ hashicorp/terraform $@
}
