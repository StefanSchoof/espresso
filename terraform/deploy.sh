#!/bin/bash -e
function deployFunc {
  pushd ../func/dist
  res=$(npx -p azure-functions-core-tools \
    func azure functionapp publish $FUNCTION_APP_NAME)
  popd
  FUNCTIONS_CODE=$(echo "$res" | sed 's/^.*code=//;t;d')
  echo "${res/$FUNCTIONS_CODE/***}"
}

function deployWeb {
  INSTRUMENTATION_KEY=$(terraform output azurerm_application_insights_web)
  FUNCTIONS_HOSTNAME=$(terraform output function_app_hostname)
  STORAGE_ACCOUNT_NAME=$(terraform output storage_account)
  sed -i \
      -e "s/<%INSTRUMENTATION_KEY%>/${INSTRUMENTATION_KEY}/" \
      -e "s/<%FUNCTIONS_CODE%>/${FUNCTIONS_CODE//\//\\/}/" `#the many / and \ escape possible /` \
      -e "s/<%FUNCTIONS_HOSTNAME%>/${FUNCTIONS_HOSTNAME}/" \
      ../web/dist/index.html
  az storage blob upload-batch -s ../web/dist -d '$web' --account-name $STORAGE_ACCOUNT_NAME
}

deployFunc
deployWeb
