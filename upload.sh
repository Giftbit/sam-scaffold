#!/usr/bin/env bash

# Upload new lambda function code.
# eg: ./upload.sh rest

STACK_NAME=CardsSearch-Alpha
FXN="$1"

if [ "$#" -ne 1 ]; then
    echo "Supply a function name to build and upload.  eg: $0 rest"
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
