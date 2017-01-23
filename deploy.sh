#!/usr/bin/env bash

# Deploy all code and update the CloudFormation stack.
# eg: ./deploy.sh
# eg: aws-profile infrastructure_admin ./deploy.sh

BUILD_ARTIFACT_BUCKET="cardssearchci-deploymentartifactbucket-1stb05anhi46z"
STACK_NAME=CardsSearch-Alpha

aws cloudformation package --template-file infrastructure/sam.yaml --s3-bucket $BUILD_ARTIFACT_BUCKET --output-template-file /tmp/SamDeploymentTemplate.yaml
echo "Executing aws cloudformation deploy..."
aws cloudformation deploy --template-file /tmp/SamDeploymentTemplate.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_IAM --parameter-overrides ElasticSearchInstanceCount=2 ElasticSearchInstanceType=t2.small.elasticsearch ElasticSearchMasterInstanceType=t2.small.elasticsearch

if [ $? -ne 0 ]; then
    # Print some help on why it failed.
    echo ""
    echo "Printing recent CloudFormation errors..."
    aws cloudformation describe-stack-events --stack-name $STACK_NAME --query 'reverse(StackEvents[?ResourceStatus==`CREATE_FAILED`||ResourceStatus==`UPDATE_FAILED`].[ResourceType,LogicalResourceId,ResourceStatusReason])' --output text
fi

# cleanup
rm /tmp/SamDeploymentTemplate.yaml
