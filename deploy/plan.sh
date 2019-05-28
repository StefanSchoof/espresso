#!/bin/bash
set -e
. bashfunctions.sh

terraform init -backend-config=/temp/backend.conf -input=false
terraform --version
for workspace in $(terraform workspace list | head -n -1 | sed 's/. //' | grep -v -e "default")
do
  echo "plan $workspace"
  terraform workspace select ${workspace/$'\r'/}
  terraform plan -lock-timeout=50m -input=false
done

