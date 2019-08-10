#!/bin/bash
set -e
. bashfunctions.sh

setTerraformVars
for workspace in $(terraform workspace list | head -n -1 | sed 's/. //' | grep -v -e "default")
do
  echo "plan $workspace"
  TF_WORKSPACE=$workspace terraform plan -lock-timeout=50m -input=false
done

