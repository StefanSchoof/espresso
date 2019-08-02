. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}
echo "one is $1"
echo "two.is $2"
echo "pwd is $PWD"
setTerraformVars
printenv | sort
#ls -laR
#terraform refresh
terraform output
writeDevopsVar "$1" "$(terraform output $1)" "" true
