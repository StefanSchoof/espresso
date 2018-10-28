#!/bin/bash
cd espresso
cat > .env << EOF
CONNECTION_STRING=$1
APPINSIGHTS_INSTRUMENTATIONKEY=$2
TAG=build$3
EOF
# docker compose use stderr for normal mesages and devops does not like that
docker-compose up -d |& cat
