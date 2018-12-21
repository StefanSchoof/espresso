#!/bin/bash
set -e
# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
echo "##vso[task.setvariable variable=branchname]$branch"
targets=( cppbuilder builder )
image="stefanschoof/espresso"
# enable cross compile with on not arm devices
if [[ ! $(uname -m) == arm* ]]
then
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi

# cache-from does not work with multistage, see https://github.com/moby/moby/issues/34715
for target in "${targets[@]}"
do
  tag=$image:build-cache-$target
  if [[ ! -z "$USECACHEFROM" ]]
  then
    cachefrom+="--cache-from $tag "
    docker pull $tag
  fi
  docker build --target $target \
    $cachefrom\
    -t $tag .
  if [[ ! -z "$PUSH" ]]
  then
    docker push $tag
  fi
done

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
