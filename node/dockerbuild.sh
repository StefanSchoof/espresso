#!/bin/bash
set -e

# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
image="stefanschoof/espresso"

buildctl build \
  --frontend dockerfile.v0 \
  --local dockerfile=. \
  --local context=. \
  --import-cache type=registry,ref=docker.io/$image:cache \
  --opt target=testresult \
  --output type=local,dest=.
buildctl build \
  --frontend dockerfile.v0 \
  --local dockerfile=. \
  --local context=. \
  --import-cache type=registry,ref=docker.io/$image:cache \
  --export-cache type=registry,ref=docker.io/$image:cache,mode=max \
  --output type=image,name=docker.io/$image:$branch,push=true

if [[ ! -z "$BUILD_BUILDID" ]]
then
  buildctl build \
    --frontend dockerfile.v0 \
    --local dockerfile=. \
    --local context=. \
    --import-cache type=registry,ref=docker.io/$image:cache \
    --output type=image,name=docker.io/$image:$BUILD_BUILDID,push=true
fi
