#!/bin/bash
cd espresso
cat > .env << EOF
CONNECTION_STRING=$1
APPINSIGHTS_INSTRUMENTATIONKEY=$2
TAG=build$3
EOF
docker-compose up -d
