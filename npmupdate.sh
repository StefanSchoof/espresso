set -e
if [ -n "$(git status --porcelain)" ]
then
  echo "there are uncommited changes, cancel"
  exit 1
fi

if [ "$1" = "-deleteBranch" ]
then
  git branch -d npmupdate
fi

function execForAll
{
  find . -maxdepth 2 -name package.json -execdir "$@" \;
}

execForAll npm install
execForAll npm update
execForAll rm -rf package-lock.json node_modules
execForAll npm install-test
execForAll npm run build
git checkout -b npmupdate
git add .
