#!/bin/bash
set -e

function buildtarget {
  tag=$image:build-cache-$1
  if [[ ! -z "$USECACHEFROM" ]]
  then
    cachefrom+="--cache-from $tag "
    docker pull $tag || true
  fi
  docker build --target $1 \
    $cachefrom \
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
  docker run --rm --privileged linuxkit/binfmt:v0.7
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
  $buildtag \
  -t $image:$branch .

if [[ ! -z "$PUSH" ]]
then
  docker push $image:${branch}
  docker push $image:build${BUILD_BUILDID}
fi
