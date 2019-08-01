. bashfunctions.sh
setTerraformVars
writeDevopsVar "$1" "$(terraform output $1)" "" true
