#!/usr/bin/env bash

set -o errexit -o pipefail # Exit on error

source functions.sh

# Set the timestamp for building/testing the canary page
TIMESTAMP=`date +%s`

# Build the canary page
./build_canary_web_page.sh $TIMESTAMP

# Ensure the canary page has the correct values
./test_canary_web_page.sh $TIMESTAMP

# Ensure docker is installed
if ! which docker > /dev/null 2>&1; then
  install_docker
fi

# Remove any previously build images
if ! require_vars DOCKER_IMAGE; then
  echo "Set required variables"
  exit 1
fi
if docker images -a | awk '{print $1}' | grep $DOCKER_IMAGE > /dev/null 2>&1; then
  for image_id in `docker images -a | grep ^${DOCKER_IMAGE} | awk '{print $3}'`; do 
    docker rmi $image_id
  done
fi

# Build docker image
sudo docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:$TIMESTAMP .

# Push docker image
if ! require_vars DOCKER_USERNAME DOCKER_PASSWORD; then
  echo "Set required variables"
  exit 2
fi
echo $DOCKER_PASSWORD | sudo docker login --username=${DOCKER_USERNAME} --password-stdin
sudo docker push $DOCKER_IMAGE
