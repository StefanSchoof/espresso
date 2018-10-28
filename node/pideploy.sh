cd espresso
# put secure varibales into env file
cat > .env << EOF
CONNECTION_STRING=$1
APPINSIGHTS_INSTRUMENTATIONKEY=$2
EOF
# docker compose use stderr for normal mesages and devops does not like that
TAG=build$3 docker-compose --no-ansi up -d 2>&1
