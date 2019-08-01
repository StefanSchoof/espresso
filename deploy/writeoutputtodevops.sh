. bashfunctions.sh
setTerraformVars
writeDevopsVar "$1" "$(terraform output $2)" "$3" true
