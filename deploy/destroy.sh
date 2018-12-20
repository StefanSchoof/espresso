#!/bin/bash
set -e
. bashfunctions.sh

# destroy costly resouces in test
terraform destroy -target azurerm_virtual_machine.dockerhost -target azurerm_iothub.iothub -auto-approve

