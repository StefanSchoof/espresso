#!/bin/bash
set -e

export DOCKER_CLI_EXPERIMENTAL=enabled
docker -v
DOCKER_CLI_EXPERIMENTAL=enabled docker buildx ls
docker version
docker info
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
#sudo service docker restart
#sleep 10
docker info

# in azure pipeline git is in detached head so git does not know it brach and we take the env var. But these are in the format /ref/head/master, so we take the basename
branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
image="stefanschoof/espresso"
docker buildx bake
#buildctl build \
#  --frontend dockerfile.v0 \
#  --local dockerfile=. \
#  --local context=. \
#  --import-cache type=registry,ref=docker.io/$image:cache \
#  --export-cache type=registry,ref=docker.io/$image:cache,mode=max \
#  --output type=image,name=docker.io/$image:$branch,push=true
#buildctl build \
#  --frontend dockerfile.v0 \
#  --local dockerfile=. \
#  --local context=. \
#  --import-cache type=registry,ref=docker.io/$image:cache \
#  --opt target=testresult \
#  --output type=local,dest=.
#
#if [[ ! -z "$BUILD_BUILDID" ]]
#then
#  buildctl build \
#    --frontend dockerfile.v0 \
#    --local dockerfile=. \
#    --local context=. \
#    --import-cache type=registry,ref=docker.io/$image:cache \
#    --output type=image,name=docker.io/$image:build$BUILD_BUILDID,push=true
#fi
