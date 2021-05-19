#!/bin/bash

HASH=`git rev-parse --short HEAD`
SERVICE_ACCOUNT="279443788353-compute@developer.gserviceaccount.com"
US_WEST_DISK="docsearch-app-west-2"

APP_TAG="gcr.io/redislabs-university/docsearch-app-staging:$HASH-$RANDOM"
WORKER_TAG="gcr.io/redislabs-university/docsearch-worker-staging:$HASH-$RANDOM"

NEW_APP_TEMPLATE="docsearch-app-staging-$HASH-$RANDOM"
NEW_WORKER_TEMPLATE="docsearch-worker-staging-$HASH-$RANDOM"

echo "Building $APP_TAG..."
docker build -t $APP_TAG . -f docker/app/Dockerfile

echo "Building $WORKER_TAG..."
docker build -t $WORKER_TAG . -f docker/worker/Dockerfile


echo "Pushing tags..."
docker push $APP_TAG
docker push $WORKER_TAG

echo "Creating new app instance template $NEW_APP_TEMPLATE from $APP_TAG"

gcloud beta compute --project=redislabs-university instance-templates \
create-with-container $NEW_APP_TEMPLATE \
--machine-type=e2-medium \
--network=projects/redislabs-university/global/networks/docsearch \
--network-tier=PREMIUM \
--metadata=google-logging-enabled=false \
--can-ip-forward \
--maintenance-policy=MIGRATE \
--service-account=$SERVICE_ACCOUNT \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--image=cos-stable-81-12871-1196-0 \
--image-project=cos-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-standard \
--boot-disk-device-name=$US_WEST_DISK \
--container-image=$APP_TAG \
--container-restart-policy=always \
--container-mount-host-path=mount-path=/data,host-path=/var/data/redis,mode=rw \
--container-env-file ./.env.staging \
--labels=container-vm=cos-stable-81-12871-1196-0


echo "Creating new worker instance template $NEW_WORKER_TEMPLATE from $WORKER_TAG"
gcloud beta compute --project=redislabs-university instance-templates \
create-with-container $NEW_WORKER_TEMPLATE \
--container-image $WORKER_TAG \
--machine-type=e2-micro \
--network=projects/redislabs-university/global/networks/docsearch \
--network-tier=PREMIUM \
--metadata=google-logging-enabled=false \
--can-ip-forward \
--maintenance-policy=MIGRATE \
--service-account=$SERVICE_ACCOUNT \
--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
--image=cos-stable-81-12871-1196-0 \
--image-project=cos-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-standard \
--boot-disk-device-name=$US_WEST_DISK \
--container-restart-policy=always \
--container-mount-host-path=mount-path=/data,host-path=/var/data/redis,mode=rw \
--container-env-file ./.env.staging \
--labels=container-vm=cos-stable-81-12871-1196-0


echo
echo "Start rolling update of staging app servers in us-west1"
echo "--------------------------------"
gcloud compute instance-groups managed rolling-action start-update docsearch-app-staging \
        --version template=$NEW_APP_TEMPLATE --zone us-west1-a

echo
echo "Start rolling update of staging worker servers in us-west1"
echo "--------------------------------"
gcloud compute instance-groups managed rolling-action start-update docsearch-worker-staging \
        --version template=$NEW_WORKER_TEMPLATE --zone us-west1-a
