#!/bin/bash
set -e

function buildtarget {
  tag=$image:build-cache-$1
  if [[ ! -z "$USECACHEFROM" ]]
  then
    cachefrom+="--cache-from $tag "
    docker pull --platform linux/arm/v6 $tag || true
  fi
  docker build --target $1 \
    --platform linux/arm/v6 \
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
image="stefanschoof/espresso"
# enable cross compile with on not arm devices
if [[ ! $(uname -m) == arm* ]]
then
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
  --platform linux/arm/v6 \
  $cachefrom \
  $dockerfilearg \
  $buildtag \
  -t $image:$branch .

if [[ ! -z "$PUSH" ]]
then
  docker push $image:${branch}
  docker push $image:build${BUILD_BUILDID}
fi
