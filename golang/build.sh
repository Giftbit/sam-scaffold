#!/usr/bin/env bash


args="$@"
if [ $# -lt 1 ]; then
    args=(src/lambdas/*/)
    args=$(basename -a $args)
fi
# Build and zip for linux on aws lambda
for arg in $args
do
    GOOS=linux GOARCH=amd64 go build -o bin/$arg src/lambdas/$arg/main.go
    zip "dist/$arg.zip" "bin/$arg"
done
