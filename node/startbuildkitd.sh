echo "activate binfmt"
docker run --privileged linuxkit/binfmt:v0.7
echo "start buildkitd"
docker run -d --privileged -p 1234:1234 --name buildkit moby/buildkit:latest  --addr tcp://0.0.0.0:1234  --oci-worker-platform linux/arm/v6
echo "copy buildctl"
sudo docker cp buildkit:/usr/bin/buildctl /usr/bin/
export BUILDKIT_HOST=tcp://0.0.0.0:1234
