#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Supply the docker repo name to upload to.  eg: $0 cards-codeb-timnjrfuk87h"
    exit 1
fi

# The name of the ECR repo as set up in CloudFormation.
# This is the Physical ID showns in the CloudFormation stack detail.
DOCKER_REPO_NAME="$1"

# Generate an ssh key so the CI image can read from the GitHub repo.
ssh-keygen -t rsa -b 4096 -f "./id_rsa" -N ""

# Store GitHub's public key as a known host to prevent MITM attacks.
ssh-keyscan -t rsa github.com > known_hosts

VERSION_STRING="latest"
docker build -t $DOCKER_REPO_NAME:$VERSION_STRING .
DOCKER_REMOTE_HOST=`aws ecr describe-repositories --repository-names $DOCKER_REPO_NAME --query "repositories[0].repositoryUri" --output text`
DOCKER_REGISTRY_ACCOUNT_ID=$(echo "$DOCKER_REMOTE_HOST" | awk -F'[.]' '{print $1}')
eval $(aws ecr get-login --region us-west-2 --registry-ids $DOCKER_REGISTRY_ACCOUNT_ID)
docker tag $DOCKER_REPO_NAME:$VERSION_STRING $DOCKER_REMOTE_HOST:$VERSION_STRING
docker push $DOCKER_REMOTE_HOST:$VERSION_STRING

echo "v---------------"
cat id_rsa.pub
echo "^--------------- This is the public SSH key.  Add it to the giftbit-ci GitHub account to give this image git access."

rm id_rsa id_rsa.pub known_hosts

echo "This image is now available in CodeBuild as: $DOCKER_REPO_NAME:$VERSION_STRING"
