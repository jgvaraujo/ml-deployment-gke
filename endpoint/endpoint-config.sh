#!/bin/bash

# If necessary uncomment the next command
# gcloud init --skip-diagnostics

PROJECT_ID=$(gcloud config get-value project)
ENDPOINTS_SERVICE_NAME="ml-model.endpoints.${PROJECT_ID}.cloud.goog"

sed "s/HOST_NAME/${ENDPOINTS_SERVICE_NAME}/g" openapi.yaml > /tmp/openapi.yaml

gcloud endpoints services deploy /tmp/openapi.yaml
gcloud services enable $ENDPOINTS_SERVICE_NAME
# gcloud endpoints services delete $ENDPOINTS_SERVICE_NAME