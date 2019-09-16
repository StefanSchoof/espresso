#!/bin/bash
set -e
. bashfunctions.sh

# destroy costly resouces in test
export TF_WORKSPACE="test"
initTerraform
terraform destroy -target azurerm_virtual_machine.dockerhost -target azurerm_iothub.iothub -auto-approve -var-file=test.tfvars

