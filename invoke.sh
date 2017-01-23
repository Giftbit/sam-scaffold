#!/usr/bin/env bash

# Invoke a lambda function.
# eg: ./upload.sh rest

STACK_NAME=CardsSearch-Alpha
FXN="$1"
JSON_FILE="$2"

if [ "$#" -ne 2 ]; then
    echo "Supply a function name to invoke and json file to invoke with.  eg: $0 rest evt.json"
    exit 1
fi

if [ ! -d "./src/lambdas/$FXN" ]; then
    echo "$FXN is not the directory of a lambda function in src/lambdas."
    exit 2
fi

if [ ! -d $JSON_FILE ]; then
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
