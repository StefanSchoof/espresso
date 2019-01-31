set -e
if [ -n "$(git status --porcelain)" ]
then
  echo "there are uncommited changes, cancel"
  exit 1
fi

function execForAll
{
  find . -maxdepth 2 -name package.json -execdir "$@" \;
}

execForAll npm install
execForAll npm update
execForAll rm -rf package-lock.json node_modules
execForAll npm install-test
git checkout -b npmupdate
git add .
