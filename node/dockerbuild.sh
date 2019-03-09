#!/bin/bash
set -e
function pullarmimage {
  # since the platform arg needs experimental daemon and there is no way do activate experimental daemon on azure pipeline => a hack...
  echo "pull armv6 image for $1"
  imagename=${1%:*}
  digest=$(DOCKER_CLI_EXPERIMENTAL="enabled" docker manifest inspect $1 | jq --raw-output '.manifests[] | select(.platform.architecture == "arm" and .platform.variant == "v6").digest')
  [[ -z "$digest" ]] && >&2 echo "found no arm image" && exit 1
  docker pull $imagename@$digest
  docker tag $imagename@$digest $1
}

function buildtarget {
  tag=$image:build-cache-$1
  if [[ ! -z "$USECACHEFROM" ]]
  then
    cachefrom+="--cache-from $tag "
    docker pull $tag || true
  fi
  docker build --target $1 \
    $cachefrom \
    $dockerfilearg \
    -t $tag .
  if [[ ! -z "$PUSH" ]]
  then
    docker push $tag
  fi
}

# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
echo "##vso[task.setvariable variable=branchname]$branch"
image="stefanschoof/espresso"
# enable cross compile with on not arm devices
if [[ ! $(uname -m) == arm* ]]
then
  for baseimage in $(sed -n 's/^FROM \([^ ]*\) .*/\1/p' Dockerfile | sort --uniq)
  do
    pullarmimage $baseimage
  done
  dockerfilearg="-f Dockerfile_x86"
  sed 's/#x86only //' Dockerfile > Dockerfile_x86
  buildtarget "qemu"
  docker run --rm --privileged $image:build-cache-qemu
fi

# cache-from does not work with multistage, see https://github.com/moby/moby/issues/34715
buildtarget "cppbuilder"
buildtarget "builder"

if [[ ! -z "$USECACHEFROM" ]]
then
  cachefrom+="--cache-from $image:$branch"
  docker pull $image:$branch || true
fi

container=$(docker create --name builder $image:build-cache-builder)
docker cp $container:/usr/src/app/junit.xml .
docker cp $container:/usr/src/app/coverage .
docker rm $container

if [[ ! -z "$BUILD_BUILDID" ]]
then
  buildtag="-t $image:build$BUILD_BUILDID "
fi

docker build \
  $cachefrom \
  $dockerfilearg \
  $buildtag \
  -t $image:$branch .

if [[ ! -z "$PUSH" ]]
then
  docker push $image:${branch}
  docker push $image:build${BUILD_BUILDID}
fi
