# You need to change these config
PROJECT_ID=effortless-pod-460108-e1
VERSION=ipa-stag

# These config will be updated automatically
REPOSITORY_NAME=$VERSION
CONTAINER_IMAGE=$VERSION
DEPLOYED_SERVICE_NAME=$VERSION
# SERVICE_ACCOUNT=$DEPLOYED_SERVICE_NAME@$PROJECT_ID.iam.gserviceaccount.com
SERVICE_ACCOUNT=cloud-run@$PROJECT_ID.iam.gserviceaccount.com
DOCKERFILE=Dockerfile
REPOSITORY_DESCRIPTION="<$VERSION> registry repo for personal assistant. Developed by Lotus. Scope: fit@hcmus students' project"
NETWORK=projects/$PROJECT_ID/global/networks/default

# You also need to look these configs carefully
REPOSITORY_FORMAT=docker
LOCATION=asia-northeast1
# CLOUD_RUN_RAM=1Gi
CLOUD_RUN_MIN_INSTANCES=1
CLOUD_RUN_MAX_INSTANCES=1
# CHAT_HISTORY_CACHED_HOST=10.90.44.155