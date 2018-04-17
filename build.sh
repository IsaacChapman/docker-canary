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
EXTRA_HTML=""
EXIT_CODE=0
TIMESTAMP=`date +%s` # Use a consistent value of time 

# Ensure jq is installed
if ! which jq > /dev/null 2>&1; then
  install_jq
fi

# Determine $REPO_ID, $REPO_NAME, $BRANCH_ID, and $BRANCH_NAME for current session using API
# http://solano-api-docs.nfshost.com/
if ! require_vars SOLANO_API_KEY; then
  EXTRA_HTML="ERROR: The \$SOLANO_API_KEY environment variable must be set to retrieve current session info."
  EXIT_CODE=$((EXIT_CODE + 2))
elif ! fetch_current_session_info; then
  EXTRA_HTML="ERROR: Could not fetch current session info:<br />${ERROR_HTML}"
  EXIT_CODE=$((EXIT_CODE + 4))
  unset ERROR_HTML
else
  EXTRA_HTML="Repo: ${REPO_NAME} (${REPO_ID})"
  EXTRA_HTML="${EXTRA_HTML}<br />Branch: ${BRANCH_NAME} (${$BRANCH_ID})"
fi

# Only searxh for previous results if we could lookup current session info above
if [[ "$EXIT_CODE" == "0" ]]; then
  if ! fetch_previous_sessions_info; then
    EXTRA_HTML="${EXTRA_HTML}<br />ERROR: Could not fetch previous session info:<br />${ERROR_HTML}"
    EXIT_CODE=$((EXIT_CODE + 8))
    unset ERROR_HTML
  elif [[ "$PREVIOUS_SESSION_HTML" == "" ]]; then
    EXTRA_HTML="${EXTRA_HTML}<br />No previous session info"
  else
    EXTRA_HTML="${EXTRA_HTML}<br />Previous Sessions:<br />${PREVIOUS_SESSION_HTML}"
  fi
fi

### BUILD the canary page
./build_canary_web_page.sh $TIMESTAMP
cp -f web/index.html $ARTIFACT_DIR/canary.html

### TEST the canary page has the correct values
./test_canary_web_page.sh $TIMESTAMP

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
