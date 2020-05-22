#!/bin/bash

# If necessary uncomment the next command
# gcloud init --skip-diagnostics

export PROJECT_ID=$(gcloud config get-value project)
export SERVICE_NAME="ml-model"
export SERVICE_IP="SERVICE_IP"

export ENDPOINTS_SERVICE_NAME="${SERVICE_NAME}.endpoints.${PROJECT_ID}.cloud.goog"

# sed "s/HOST_NAME/${ENDPOINTS_SERVICE_NAME}/g" openapi.yaml > /tmp/openapi.yaml
# sed -i "s/SERVICE_IP/${SERVICE_IP}/g" /tmp/openapi.yaml
envsubst <openapi.yaml >/tmp/openapi.yaml

_DEPLOY_CMD="gcloud endpoints services deploy /tmp/openapi.yaml"
_UNDELETE_CMD="gcloud endpoints services undelete ${ENDPOINTS_SERVICE_NAME}"

_MSG="\n\033[1;32mPOSSIBLE SOLUTION\033[0m: Probably you've recently\
 deleted this service. We're undeleting it and trying again...\n"

$_DEPLOY_CMD || (echo -e $_MSG && $_UNDELETE_CMD && $_DEPLOY_CMD)
gcloud services enable ${ENDPOINTS_SERVICE_NAME}
# gcloud endpoints services delete $ENDPOINTS_SERVICE_NAME

unset PROJECT_ID SERVICE_NAME SERVICE_IP ENDPOINTS_SERVICE_NAME