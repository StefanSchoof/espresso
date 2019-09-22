#!/bin/bash
set -e
. ./bashfunctions.sh

function deployFunc {
  pushd ../func
  res=$(npx -p azure-functions-core-tools \
    func azure functionapp publish $FUNCTION_APP)
  popd
  FUNCTIONS_CODE=$(echo "$res" | sed 's/^.*code=//;t;d')
  [[ -z "$FUNCTIONS_CODE" ]] && echo "##vso[task.logissue type=error]found no functionscode" && exit 1
  # prevent to get the code into the log
  writeDevopsVar "FunctionsCode" "$FUNCTIONS_CODE" true
  echo "$res"
}

function deployWeb {
  sed -i \
      -e "s/<%INSTRUMENTATION_KEY%>/${AZURERM_APPLICATION_INSIGHTS_WEB}/" \
      -e "s/<%FUNCTIONS_CODE%>/${FUNCTIONS_CODE//\//\\/}/" `#the many / and \ escape possible /` \
      -e "s/<%FUNCTIONS_HOSTNAME%>/${FUNCTION_APP_HOSTNAME}/" \
      ../web/index.html
  az storage blob upload-batch -s ../web -d '$web' --account-name $STORAGE_ACCOUNT
}

deployFunc
deployWeb
