#!/usr/bin/env bash

# constants
HEADER_API_KEY_NAME=X-Tddium-Api-Key
HEADER_CLIENT_NAME=X-Tddium-Client-Version
HEADER_CLIENT_VALUE=tddium-client_0.4.4
SOLANO_API_URL=https://ci.solanolabs.com/1

set -o errexit -o pipefail # Exit on error

source functions.sh

### PREP

if require_vars TDDIUM TDDIUM_SESSION_ID; then
  ARTIFACT_DIR=${HOME}/results/${TDDIUM_SESSION_ID}/session
else
  ARTIFACT_DIR=`mktemp -d -t canary-artifacts`
fi
mkdir -p $ARTIFACT_DIR
TIMESTAMP=`date +%s` # Use a consistent value of time 

# Ensure jq is installed
if ! which jq > /dev/null 2>&1; then
  install_jq
fi

# Determine $REPO_ID, $REPO_NAME, $BRANCH_ID, and $BRANCH_NAME for current session using API
# http://solano-api-docs.nfshost.com/
if ! require_vars SOLANO_API_KEY; then
  echo "ERROR: \$SOLANO_API_KEY needs to be set" | tee -a $ARTIFACT_DIR/errors.txt
elif ! fetch_current_session_info; then
  echo "ERROR: Could not fetch current session information" | tee -a $ARTIFACT_DIR/errors.txt
else
  BUILD_INFO_HTML="Repo: ${REPO_NAME} (${REPO_ID})<br />Branch: ${BRANCH_NAME} (${BRANCH_ID})"
fi

# Only searxh for previous results if we could lookup current session info above
if [ ! -z "$BUILD_INFO_HTML" ]; then
if [[ "$EXIT_CODE" == "0" ]]; then
  if ! fetch_previous_sessions_info; then
    echo "ERROR: Could not fetch previous session information" | tee -a $ARTIFACT_DIR/errors.txt
  fi
fi

### BUILD the canary page
./build_canary_web_page.sh $TIMESTAMP
cp -f web/index.html $ARTIFACT_DIR/canary.html

### TEST the canary page has the correct values
./test_canary_web_page.sh $TIMESTAMP

# Only deploy if $DEPLOY_DOCKER == true
if [[ -z "$DEPLOY_DOCKER" || "$DEPLOY_DOCKER" != "true" ]]; then 
  echo "NOTICE: Not deploying to Docker hub, as \$DEPLOY_DOCKER != 'true'"
  exit
fi

# Ensure docker is installed
if ! which docker > /dev/null 2>&1; then
  install_docker
fi

# Remove any previously built images
if ! require_vars DOCKER_IMAGE; then
  echo "Set required variables"
  exit 1
fi
if sudo docker images -a | awk '{print $1}' | grep $DOCKER_IMAGE > /dev/null 2>&1; then
  for image_id in `docker images -a | grep ^${DOCKER_IMAGE} | awk '{print $3}'`; do 
    sudo docker rmi $image_id
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
