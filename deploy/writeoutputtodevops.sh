. bashfunctions.sh

export TF_WORKSPACE=${RELEASE_ENVIRONMENTNAME:-test}
writeDevopsVar "$1" "$(terraform output $1)" "" true
