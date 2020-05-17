#!/bin/bash

# If necessary uncomment the next command
# gcloud init --skip-diagnostics

PROJECT_ID=$(gcloud config get-value project)
ENDPOINTS_SERVICE_NAME="ml-model.endpoints.${PROJECT_ID}.cloud.goog"

sed "s/HOST_NAME/${ENDPOINTS_SERVICE_NAME}/g" openapi.yaml > /tmp/openapi.yaml

_DEPLOY_CMD="gcloud endpoints services deploy /tmp/openapi.yaml"
_UNDELETE_CMD="gcloud endpoints services undelete ${ENDPOINTS_SERVICE_NAME}"
_MSG="\n\033[1;32mPOSSIBLE SOLUTION\033[0m: Probably you've recently deleted this service. We're undeleting it and trying again...\n"
$_DEPLOY_CMD || echo -e $_MSG && $_UNDELETE_CMD && $_DEPLOY_CMD
gcloud services enable $ENDPOINTS_SERVICE_NAME
# gcloud endpoints services delete $ENDPOINTS_SERVICE_NAME