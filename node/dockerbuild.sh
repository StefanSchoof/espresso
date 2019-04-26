#!/bin/bash
set -e

# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
image="stefanschoof/espresso"

#echo "build builder"
#buildctl build \
#  --frontend dockerfile.v0 \
#  --local dockerfile=. \
#  --local context=. \
#  --import-cache type=registry,ref=docker.io/$image:cache \
#  --opt target=builder \
#  --output type=docker,name=builder | docker load
#echo "copy test results"
#container=$(docker create --name builder builder)
#docker cp $container:/usr/src/app/junit.xml .
#docker cp $container:/usr/src/app/coverage .
#docker rm $container
echo "build final image"
buildctl build \
  --frontend dockerfile.v0 \
  --local dockerfile=. \
  --local context=. \
  --import-cache type=registry,ref=docker.io/$image:cache \
  --export-cache type=registry,ref=docker.io/$image:cache \
  --output type=image,name=docker.io/$image:$branch,push=true

if [[ ! -z "$BUILD_BUILDID" ]]
then
  echo "push image with buildidtag"
  buildctl build \
    --frontend dockerfile.v0 \
    --local dockerfile=. \
    --local context=. \
    --import-cache type=registry,ref=docker.io/$image:cache \
    --output type=image,name=docker.io/$image:$BUILD_BUILDID,push=true
fi
