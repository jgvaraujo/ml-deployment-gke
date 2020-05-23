#!/bin/bash

# If necessary uncomment the next command
# gcloud init --skip-diagnostics

PROJECT_ID=$(gcloud config get-value project)
ENDPOINTS_NAME="ml-model"
ENDPOINTS_SERVICE_NAME="${ENDPOINTS_NAME}.endpoints.${PROJECT_ID}.cloud.goog"

JKEY="{.status.loadBalancer.ingress[].ip}"
SERVICE_NAME="ml-service-lb"
SERVICE_IP=$(kubectl get svc ${SERVICE_NAME} -o jsonpath=${JKEY})

sed "s/ENDPOINTS_SERVICE_NAME/${ENDPOINTS_SERVICE_NAME}/g" openapi.yaml > /tmp/openapi.yaml
sed -i "s/SERVICE_IP/${SERVICE_IP}/g" /tmp/openapi.yaml

DEPLOY_CMD="gcloud endpoints services deploy /tmp/openapi.yaml"
UNDELETE_CMD="gcloud endpoints services undelete ${ENDPOINTS_SERVICE_NAME}"

MSG="\n\033[1;32mPOSSIBLE SOLUTION\033[0m: Probably you've recently\
 deleted this service. We're undeleting it and trying again...\n"

$DEPLOY_CMD || (echo -e $MSG && $UNDELETE_CMD && $DEPLOY_CMD)
gcloud services enable ${ENDPOINTS_SERVICE_NAME}
# gcloud endpoints services delete $ENDPOINTS_SERVICE_NAME