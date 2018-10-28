cd $(dirname "$0")
/usr/local/bin/docker-compose pull --quiet
config=$(/usr/local/bin/docker-compose config)
container=$(echo -e "$config" | sed -n "s/    container_name: \(.*\)/\1/p")
image=$(echo -e "$config" | sed -n "s/    image: \(.*\)/\1/p")
running=$(docker inspect  --format "{{.Image}}" $container)
latest=$(docker inspect --format "{{.Id}}" $image)
if [ "$running" != "$latest" ]; then
  echo "espresso needs update"
fi
