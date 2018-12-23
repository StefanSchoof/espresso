#!/bin/bash
set -e
function pullarmimage {
  # since the platform arg needs experimental daemon and there is no way do activate experimental daemon on azure pipeline => a hack...
  tag=${2:+:$2}
  digest=$(DOCKER_CLI_EXPERIMENTAL="enabled" docker manifest inspect $1$tag | jq --raw-output '.manifests[] | select(.platform.architecture == "arm").digest')
  docker pull $1@$digest
  docker tag $1@$digest $1$tag
}

# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
echo "##vso[task.setvariable variable=branchname]$branch"
targets=( cppbuilder builder )
image="stefanschoof/espresso"
# enable cross compile with on not arm devices
if [[ ! $(uname -m) == arm* ]]
then
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
  qemuimage=$(docker build --quiet --file Dockerfile_qemu .)
  qemucontainer=$(docker create $qemuimage)
  docker cp $qemucontainer:/usr/bin/qemu-arm-static .
  docker rm $qemucontainer
  pullarmimage alpine
  pullarmimage node 10-alpine
  sed --in-place 's/#x86only //' Dockerfile
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
