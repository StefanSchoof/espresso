set -e
TMPDIR=$(mktemp --directory)

function cleanup {
  rm -rf "$TMPDIR"
  echo "Deleted temp working directory $TMPDIR"
}

trap cleanup EXIT
cd $TMPDIR
version=${1:-$(curl https://checkpoint-api.hashicorp.com/v1/check/terraform | jq '.current_version' -r)}
path="https://releases.hashicorp.com/terraform/$version"
# fingerprint taken from https://www.hashicorp.com/security.html
gpg --keyserver pgp.mit.edu --recv-keys "91A6 E7F8 5D05 C656 30BE F189 5185 2D87 348F FC4C"
curl --fail -Os "$path/terraform_${version}_linux_amd64.zip"
curl --fail -Os "$path/terraform_${version}_SHA256SUMS.sig"
curl --fail -Os "$path/terraform_${version}_SHA256SUMS"
gpg --verify "terraform_${version}_SHA256SUMS.sig" "terraform_${version}_SHA256SUMS"
sha256sum --ignore-missing -c "terraform_${version}_SHA256SUMS"
unzip "terraform_${version}_linux_amd64.zip"
sudo mv terraform /usr/local/bin
terraform --version
