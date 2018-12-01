#!/bin/bash
# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
echo "##vso[task.setvariable variable=branchname]$branch"
targets=( node cppbuilder builder )
image="stefanschoof/espresso"
if [[ ! -z "$BUILD_BUILDID" ]]
then
  buildtagarm="-t $image:build${BUILD_BUILDID}_arm "
  buildtagx86="-t $image:build${BUILD_BUILDID}_amd64 "
fi

if [[ ! $(uname -m) == arm* ]]
then
  docker build -f Dockerfile_amd64 -t $image:${branch}_amd64 $buildtagx86 .
  # enable cross compile with on not arm devices
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi

if [[ ! -z "$USECACHEFROM" ]]
then
  cachefrom="--cache-from $image:$branch "
  # cache-from does not work with multistage, see https://github.com/moby/moby/issues/34715
  for target in "${targets[@]}"
  do
    tag=$image:build-cache-$target
    docker pull $tag
    cachefrom+="--cache-from $tag "
    docker build --target $target \
      $cachefrom\
      -t $tag .
    if [[ ! -t "$PUSH" ]]
    then
      echo docker push $tag
    fi
  done

  docker pull $image:$branch
fi

docker build \
  $cachefrom \
  $buildtagarm \
  -t $image:${branch}_arm .

if [[ ! -z "$PUSH" ]]
then
  docker push $image:${branch}_arm
  docker push $image:${branch}_amd64
  docker push $image:build${BUILD_BUILDID}_arm
  docker push $image:build${BUILD_BUILDID}_amd64
  export DOCKER_CLI_EXPERIMENTAL=enabled
  docker manifest create --amend $image:${branch} $image:${branch}_arm $image:${branch}_amd64
  docker manifest annotate $image:${branch} $image:${branch}_amd64 --os linux --arch amd64
  docker manifest annotate $image:${branch} $image:${branch}_arm --os linux --arch arm
  docker manifest push $image:${branch}
#  docker pull $image:${branch}
  docker manifest create --amend $image:build${BUILD_BUILDID} $image:build${BUILD_BUILDID}_arm $image:build${BUILD_BUILDID}_amd64
  docker manifest annotate $image:build${BUILD_BUILDID} $image:build${BUILD_BUILDID}_amd64 --os linux --arch amd64
  docker manifest annotate $image:build${BUILD_BUILDID}  $image:build${BUILD_BUILDID}_arm --os linux --arch arm
  docker manifest push $image:build${BUILD_BUILDID}
fi
