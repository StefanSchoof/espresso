#!/bin/bash
set -e
. ./bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}

function deployFunc {
  functionAppName=$(terraform output function_app)
  pushd ../func
  res=$(npx -p azure-functions-core-tools \
    func azure functionapp publish $functionAppName)
  popd
  FUNCTIONS_CODE=$(echo "$res" | sed 's/^.*code=//;t;d')
  [[ -z "$FUNCTIONS_CODE" ]] && >&2 echo "found no functionscode" && exit 1
  # prevent to get the code into the log
  writeDevopsVar "FunctionsCode" "$FUNCTIONS_CODE" true
  echo "$res"
}

function deployWeb {
  INSTRUMENTATION_KEY=$(terraform output azurerm_application_insights_web)
  FUNCTIONS_HOSTNAME=$(terraform output function_app_hostname)
  STORAGE_ACCOUNT_NAME=$(terraform output storage_account)
  sed -i \
      -e "s/<%INSTRUMENTATION_KEY%>/${INSTRUMENTATION_KEY}/" \
      -e "s/<%FUNCTIONS_CODE%>/${FUNCTIONS_CODE//\//\\/}/" `#the many / and \ escape possible /` \
      -e "s/<%FUNCTIONS_HOSTNAME%>/${FUNCTIONS_HOSTNAME}/" \
      ../web/index.html
  az storage blob upload-batch -s ../web -d '$web' --account-name $STORAGE_ACCOUNT_NAME
}

deployFunc
deployWeb
