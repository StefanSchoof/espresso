. bashfunctions.sh
echo "one is $1"
echo "two.is $2"
echo "pwd is $PWD"
setTerraformVars
terraform output
writeDevopsVar "$1" "$(terraform output $1)" "" true
