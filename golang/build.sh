#!/usr/bin/env bash


if [ $# -lt 1 ]; then
    echo "Error: Expected a lambda name"
    exit 1
fi

# Build and zip for linux on aws lambda
for arg in "$@"
do
    GOOS=linux GOARCH=amd64 go build -o bin/$arg src/lambdas/$arg/main.go
    zip "dist/$arg.zip" "bin/$arg"
done
