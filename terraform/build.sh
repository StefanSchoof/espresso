#!/bin/bash -e
. terraformfunctions.sh

echo $DOWNLOADSECUREFILE1_SECUREFILEPATH
echo $AGENT_TEMPDIRECTORY
printenv

terraform init -backend-config=${AGENT_TEMPDIRECTORY:-.}/backend.conf -input=false
terraform --version
for workspace in $(terraform workspace list | sed 's/. //' | grep -v -e "default" -e "^$")
do
  echo "plan $workspace"
  TF_WORKSPACE=$workspace terraform plan -input=false
done

