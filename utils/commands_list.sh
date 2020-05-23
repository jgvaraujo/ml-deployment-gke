##############################################
### IMPORTANT!                             ###
###  Do not use this commands in sequence. ###
### Just copy and paste in you terminal    ###
### as needed.                             ###
##############################################

# define main values
_CLUSTER=ml-cluster        # name
_N_NODES=1                 # size
_ZONE=southamerica-east1-b # zonal cluster
_MACHINE_TYPE=n1-highmem-2 # 2 vCPUs and 13GB vRAM

# create a cluster with this specifications
gcloud container clusters create $_CLUSTER \
    --num-nodes $_N_NODES \
    --machine-type $_MACHINE_TYPE \
    --zone $_ZONE

# check nodes state
kubectl get nodes,pods,svc

# get service external ip
SERVICE_NAME="ml-service-lb"
kubectl get svc ${SERVICE_NAME} -o jsonpath={.status.loadBalancer.ingress[].ip}

# check pods state every 0.5 seconds
# this command is greate to see how a new deployment is going
watch -n 0.5 kubectl get pods

# check rollout status of a new deployment
kubectl rollout status deployment/ml-deployment

# delete cluster
gcloud container clusters delete $_CLUSTER --zone $_ZONE

