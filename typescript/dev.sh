#!/usr/bin/env bash

# A few bash commands to make development against dev environment easy.
# Set the properties below to sensible values for your project.

# The name of your CloudFormation stack.  Two developers can share a stack by
# sharing this value, or have their own with different values.
STACK_NAME="MyProject"

# The name of an S3 bucket on your account to hold deployment artifacts.
BUILD_ARTIFACT_BUCKET="mys3artifactbucket"

# Parameter values for the sam template.  see: `aws cloudformation deploy help`
PARAMETER_OVERRIDES=""
#PARAMETER_OVERRIDES="--parameter-overrides"
#PARAMETER_OVERRIDES+=" KeyOne=value"
#PARAMETER_OVERRIDES+=" KeyTwo=value"

USAGE="usage: $0 <command name>\nvalid command names: build delete deploy invoke upload"


set -eu

if ! type "aws" &> /dev/null; then
    echo "'aws' was not found in the path.  Install awscli and try again."
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Error: expected a command."
    echo -e $USAGE
    exit 1
fi

COMMAND="$1"

if [ "$COMMAND" = "build" ]; then
    # Build one or more lambda functions.
    # eg: ./dev.sh build rest rollup
    # eg: ./dev.sh build

    BUILD_ARGS=""
    if [ "$#" -ge 2 ]; then
        BUILD_ARGS="--env.fxn=$2"
        for ((i=3;i<=$#;i++)); do
            BUILD_ARGS="$BUILD_ARGS,${!i}";
        done
    fi

    npm run build -- $BUILD_ARGS

elif [ "$COMMAND" = "delete" ]; then
    aws cloudformation delete-stack --stack-name $STACK_NAME

elif [ "$COMMAND" = "deploy" ]; then
    # Deploy all code and update the CloudFormation stack.
    # eg: ./dev.sh deploy
    # eg: aws-profile infrastructure_admin ./deploy.sh deploy

    npm run build

    OUTPUT_TEMPLATE_FILE="/tmp/SamDeploymentTemplate.`date "+%s"`.yaml"
    aws cloudformation package --template-file infrastructure/sam.yaml --s3-bucket $BUILD_ARTIFACT_BUCKET --output-template-file "$OUTPUT_TEMPLATE_FILE"

    echo "Executing aws cloudformation deploy..."
    aws cloudformation deploy --template-file "$OUTPUT_TEMPLATE_FILE" --stack-name $STACK_NAME --capabilities CAPABILITY_IAM $PARAMETER_OVERRIDES

    # cleanup
    rm "$OUTPUT_TEMPLATE_FILE"

elif [ "$COMMAND" = "invoke" ]; then
    # Invoke a lambda function.
    # eg: ./dev.sh invoke myfunction myfile.json

    if [ "$#" -ne 3 ]; then
        echo "Supply a function name to invoke and json file to invoke with.  eg: $0 invoke myfunction myfile.json"
        exit 1
    fi

    FXN="$2"
    JSON_FILE="$3"

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
        echo "Could not discover the LogicalResourceId of $FXN.  Check that there is a ${FXN_UPPER_CAMEL_CASE}Function Resource inside infrastructure/sam.yaml and check that it has been deployed."
        exit 1
    fi

    aws --cli-read-timeout 300 lambda invoke --function-name $FXN_ID --payload fileb://$JSON_FILE /dev/stdout

elif [ "$COMMAND" = "upload" ]; then
    # Upload new lambda function code.
    # eg: ./dev.sh upload myfunction

    if [ "$#" -ne 2 ]; then
        echo "Supply a function name to build and upload.  eg: $0 upload myfunction"
        exit 1
    fi

    FXN="$2"

    if [ ! -d "./src/lambdas/$FXN" ]; then
        echo "$FXN is not the directory of a lambda function in src/lambdas."
        exit 2
    fi

    npm run build -- --env.fxn=$FXN

    # Search for the ID of the function assuming it was named something like FxnFunction where Fxn is the uppercased form of the dir name.
    FXN_UPPERCASE="$(tr '[:lower:]' '[:upper:]' <<< ${FXN:0:1})${FXN:1}"
    FXN_ID="$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --query "StackResources[?ResourceType==\`AWS::Lambda::Function\`&&starts_with(LogicalResourceId,\`$FXN_UPPERCASE\`)].PhysicalResourceId" --output text)"
    if [ $? -ne 0 ]; then
        echo "Could not discover the LogicalResourceId of $FXN.  Check that there is a ${FXN_UPPER_CAMEL_CASE}Function Resource inside infrastructure/sam.yaml and check that it has been deployed."
        exit 1
    fi

    aws lambda update-function-code --function-name $FXN_ID --zip-file fileb://./dist/$FXN/$FXN.zip

else
    echo "Error: unknown command name '$COMMAND'."
    echo -e $USAGE
    exit 2

fi
