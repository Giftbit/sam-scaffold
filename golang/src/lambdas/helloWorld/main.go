package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
)

func Handler() string {
	return fmt.Sprintf("Hello world")
}

func main() {
	lambda.Start(Handler)
}
