#!/usr/bin/env bash

# A few bash commands to make development against dev environment easy.
# Set the two properties below to sensible values for your project.

# The name of your CloudFormation stack.  Two developers can share a stack by
# sharing this value, or have their own with different values.
STACK_NAME="MyProject"

# The name of an S3 bucket on your account to hold deployment artifacts.
BUILD_ARTIFACT_BUCKET="mys3artifactbucket"



if ! type "aws" &> /dev/null; then
    echo "'aws' was not found in the path.  Install awscli and try again."
    exit 1
fi

COMMAND="$1"

if [ "$COMMAND" = "build" ]; then
    # Build one or more lambda functions.
    # eg: ./sam.sh build rest rollup
    # eg: ./sam.sh build

    BUILD_ARGS=""
    for ((i=2;i<=$#;i++)); do
        BUILD_ARGS="$BUILD_ARGS --fxn=${!i}";
    done

    npm run build -- $BUILD_ARGS

elif [ "$COMMAND" = "delete" ]; then
    aws cloudformation delete-stack --stack-name $STACK_NAME

    if [ $? -ne 0 ]; then
        # Print some help on why it failed.
        echo ""
        echo "Printing recent CloudFormation errors..."
        aws cloudformation describe-stack-events --stack-name $STACK_NAME --query 'reverse(StackEvents[?ResourceStatus==`CREATE_FAILED`||ResourceStatus==`UPDATE_FAILED`].[ResourceType,LogicalResourceId,ResourceStatusReason])' --output text
    fi

elif [ "$COMMAND" = "deploy" ]; then
    # Deploy all code and update the CloudFormation stack.
    # eg: ./sam.sh deploy
    # eg: aws-profile infrastructure_admin ./deploy.sh

    aws cloudformation package --template-file infrastructure/sam.yaml --s3-bucket $BUILD_ARTIFACT_BUCKET --output-template-file /tmp/SamDeploymentTemplate.yaml
    if [ $? -ne 0 ]; then
        exit 1
    fi

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

elif [ "$COMMAND" = "invoke" ]; then
    # Invoke a lambda function.
    # eg: ./sam.sh invoke myfunction myfile.json

    FXN="$2"
    JSON_FILE="$3"

    if [ "$#" -ne 3 ]; then
        echo "Supply a function name to invoke and json file to invoke with.  eg: $0 invoke myfunction myfile.json"
        exit 1
    fi

    if [ ! -d "./src/lambdas/$FXN" ]; then
        echo "$FXN is not the directory of a lambda function in src/lambdas."
        exit 2
    fi

    if [ ! -f $JSON_FILE ]; then
        echo "$JSON_FILE does not exist.";
        exit 3
    fi

    # Search for the ID of the function assuming it was named something like FxnFunction where Fxn is the uppercased form of the dir name.
    FXN_UPPERCASE="$(tr '[:lower:]' '[:upper:]' <<< ${FXN:0:1})${FXN:1}"
    FXN_ID="$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --query "StackResources[?ResourceType==\`AWS::Lambda::Function\`&&starts_with(LogicalResourceId,\`$FXN_UPPERCASE\`)].PhysicalResourceId" --output text)"
    if [ $? -ne 0 ]; then
        echo "Could not discover the LogicalResourceId of $FXN.  Check that there is a ${FXN_UPPERCASE}Function Resource inside infrastructure/sam.yaml and check that it has been deployed."
        exit 1
    fi

    aws lambda invoke --function-name $FXN_ID --payload fileb://$JSON_FILE /dev/stdout

elif [ "$COMMAND" = "upload" ]; then
    # Upload new lambda function code.
    # eg: ./sam.sh upload myfunction

    FXN="$2"

    if [ "$#" -ne 2 ]; then
        echo "Supply a function name to build and upload.  eg: $0 upload myfunction"
        exit 1
    fi

    if [ ! -d "./src/lambdas/$FXN" ]; then
        echo "$FXN is not the directory of a lambda function in src/lambdas."
        exit 2
    fi

    npm run build -- --fxn=$FXN
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Search for the ID of the function assuming it was named something like FxnFunction where Fxn is the uppercased form of the dir name.
    FXN_UPPERCASE="$(tr '[:lower:]' '[:upper:]' <<< ${FXN:0:1})${FXN:1}"
    FXN_ID="$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --query "StackResources[?ResourceType==\`AWS::Lambda::Function\`&&starts_with(LogicalResourceId,\`$FXN_UPPERCASE\`)].PhysicalResourceId" --output text)"
    if [ $? -ne 0 ]; then
        echo "Could not discover the LogicalResourceId of $FXN.  Check that there is a ${FXN_UPPERCASE}Function Resource inside infrastructure/sam.yaml and check that it has been deployed."
        exit 1
    fi

    aws lambda update-function-code --function-name $FXN_ID --zip-file fileb://./dist/$FXN/$FXN.zip

else
    echo "Error: unknown command name '$COMMAND'."
    echo "  usage: $0 <command name>"
    echo "Valid command names: build deploy invoke upload"
    exit 2

fi
