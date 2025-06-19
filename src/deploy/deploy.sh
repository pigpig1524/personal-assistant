#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

CONFIG_FILE_NAME=${1:-"stag_config"}

read_config() {
    TARGET_CONFIGS='
        PROJECT_ID
        VERSION
        REPOSITORY_NAME
        CONTAINER_IMAGE
        DEPLOYED_SERVICE_NAME
        SERVICE_ACCOUNT
        DOCKERFILE
        REPOSITORY_FORMAT
        REPOSITORY_DESCRIPTION
        NETWORK
        LOCATION
        CLOUD_RUN_MIN_INSTANCES
        CLOUD_RUN_MAX_INSTANCES'

    echo "${green}GCP configuration parameters:${reset}"
    for config in $TARGET_CONFIGS; do
        unset -v $config
    done

    CONFIG_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/config/"${CONFIG_FILE_NAME}".sh
    chmod +x $CONFIG_DIR
    echo "params $1"
    echo "${CONFIG_DIR}"
    source $CONFIG_DIR

    for config in $TARGET_CONFIGS; do
        echo "${green} -${config}=${!config}${reset}"
    done
}

login() {
    echo "${green}Login with your user account or deployment service account corresponding to project ${PROJECT_ID}${reset}"
    gcloud auth login

    echo "${green}Set project to ${PROJECT_ID}${reset}"
    gcloud config set project ${PROJECT_ID}

    echo "${green}User credentials provided by using the gcloud CLI:${reset}"
    gcloud auth application-default login

    echo "${green}Update or add a quota project in ADC for billing and quota limits${reset}"
    gcloud auth application-default set-quota-project ${PROJECT_ID}
}

logout() {
    echo "${green}Revoke user credentials provided by the gcloud CLI${reset}"
    gcloud auth revoke --all

    echo "${green}Unset application-default user credentials${reset}"
    gcloud auth application-default revoke

    echo "${green}Logout completed. All credentials have been revoked.${reset}"
}

_increment_tag() {
    local latest_tag=$1
    IFS='.' read -r -a version_parts <<< "$latest_tag"
    version_parts[2]=$((version_parts[2] + 1))  # Increment the patch version
    echo "${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
}

# Helper function to validate the tag format (e.g., 1.0.0)
_is_valid_tag() {
    [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# TBU
check_requirements() {
    if ! gcloud auth list >/dev/null 2>&1; then
        echo -e "${red}GCP authentication is not configured. Exiting.${reset}"
        logout;
        read -p "Press Ctrl + C to exit";
        exit 1;
    fi
    if ! docker info > /dev/null 2>&1; then
        echo "${red}This script uses docker, and it isn't running - please start docker and try again!${reset}";
        logout;
        read -p "Press Ctrl + C to exit";
        exit 1;
    fi
}

# Check if the artifact repository exists in the specified GCP location
verify_and_create_repo() {
    echo "${green}Checking if artifact repository exists...${reset}"
    if ! gcloud artifacts repositories list \
                --location="$LOCATION" \
                --filter="name:$REPOSITORY_NAME" \
                --format="value(name)" | grep -q "$REPOSITORY_NAME";
    then
        echo "${green}Creating repository $REPOSITORY_NAME...${reset}"
        gcloud artifacts repositories create "$REPOSITORY_NAME" \
            --repository-format="$REPOSITORY_FORMAT" \
            --location="$LOCATION" \
            --description="$REPOSITORY_DESCRIPTION" \
            --async
    else
        echo "${green}Repository $REPOSITORY_NAME already exists.${reset}"
    fi
}

# Fetching the latest image tag for the container image, or setting default if none exist
tag() {
    echo "${green}Fetching latest container image tag...${reset}"
    latest_tag=$(gcloud artifacts docker tags list \
                $LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/$CONTAINER_IMAGE \
                --sort-by=~CREATE_TIME --limit=1 --format="value(tag)" 2>/dev/null)

    if [ -z "$latest_tag" ] || ! _is_valid_tag "$latest_tag"; then
        echo "${red}No valid existing tags found. Using default tag 1.0.0${reset}"
        new_tag="1.0.0"
    else
        new_tag=$(_increment_tag "$latest_tag")
    fi

    FULL_IMAGE="$LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/$CONTAINER_IMAGE:$new_tag"
    echo "${green}New container image tag: ${FULL_IMAGE}${reset}"
}


# Building Docker container image
build() {
    echo "${green}Building container image...${reset}"
    docker build -f $DOCKERFILE -t $FULL_IMAGE .
}


# Pushing the Docker container image to Artifact Registry
push() {
    echo "${green}Pushing container image...${reset}"
    docker push $FULL_IMAGE || {
        echo "${red}Failed to push container image. Exiting.${reset}";
        logout;
        # restore_file "./backend/.env";
        # restore_file "./backend/app/conf/log/local.conf";
        # restore_file "./backend/app/conf/log/indexing.conf";
        read -p "Press Ctrl + C to exit";
        exit 1;
    }
}


# Something need to fill in the future
# --memory $CLOUD_RUN_RAM \


# Deploy the container image to Google Cloud Run
deploy() {
    echo "${green}Deploying container to Cloud Run...${reset}"

    gcloud run deploy $DEPLOYED_SERVICE_NAME \
        --image $FULL_IMAGE \
        --region $LOCATION \
        --platform managed \
        --network $NETWORK \
        --port 8080 \
        --min $CLOUD_RUN_MIN_INSTANCES \
        --max-instances $CLOUD_RUN_MAX_INSTANCES \
        --service-account $SERVICE_ACCOUNT \
        --allow-unauthenticated || {
            echo "${red}Cloud Run deployment failed. Exiting.${reset}";
            logout;
            # restore_file "./backend/.env";
            # restore_file "./backend/app/conf/log/local.conf";
            # restore_file "./backend/app/conf/log/indexing.conf";
            read -p "Press Ctrl + C to exit";
            exit 1;
        }

    echo "${green}Deployment to Cloud Run completed successfully.${reset}"
}

read_config;
login;
check_requirements;
verify_and_create_repo;
tag;
build;
push;
deploy;
logout;