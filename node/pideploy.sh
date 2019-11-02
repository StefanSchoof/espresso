set -e
cd espresso
# put secure varibales into env file
cat > .env << EOF
CONNECTION_STRING=$1
APPINSIGHTS_INSTRUMENTATIONKEY=$2
EOF
# docker compose use stderr for normal messages and devops shows them as errors
TAG=$3 TestingCommand=$4 docker-compose --no-ansi pull 2>&1
TAG=$3 TestingCommand=$4 docker-compose --no-ansi up -d 2>&1
