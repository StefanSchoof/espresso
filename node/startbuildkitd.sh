#!/bin/bash
set -e

docker rm --force buildkit || true
docker run -d --privileged -p 1234:1234 --name buildkit moby/buildkit:v0.6.4  --addr tcp://0.0.0.0:1234  --oci-worker-platform linux/arm/v6
sudo docker cp buildkit:/usr/bin/buildctl /usr/bin/
export BUILDKIT_HOST=tcp://0.0.0.0:1234
