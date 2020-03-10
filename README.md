# sam-scaffold
A template for an AWS SAM project with continuous integration.

[SAM](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md) is an extension of AWS's CloudFormation that makes it easier to define serverless applications.  It is unopinionated on language choice, build tools, or project layout.  This example project provides a set of opinions on those choices.  It can be cloned and used as is to get a serverless project up and running quickly, or it can be used as a guideline for your own project.

This project features templates for [Go](https://golang.org/), JavaScript [ES2015](https://en.wikipedia.org/wiki/ECMAScript#6th_Edition_-_ECMAScript_2015) and [TypeScript](https://www.typescriptlang.org/).  READMEs in each project directory provide language-specific information.

## Project Structure

```
.
├── dev.sh
├── infrastructure
│   └── sam.yaml
└── src
    └── lambdas
        └── ...
```

The behaviour of a lambda function is determined by its source code (inside a subdirectory of `src/lambdas`) and the other serverless resources it has access to (inside the CloudFormation template `infrastructure/sam.yaml`).

### dev.sh

Building the project and managing the development account is easily done with the included script `dev.sh`.  The script requires the [aws cli](https://aws.amazon.com/cli/) installed and configured for a development account.  For security reasons this should not be your production account.  It also requires bash, which is a useful tool even on [Windows](http://stackoverflow.com/questions/36352627/how-to-enable-bash-in-windows-10-developer-preview).
 
Edit the top of `dev.sh` and replace `STACK_NAME` with a name that describes the project and replace `BUILD_ARTIFACT_BUCKET` with the name of an S3 bucket you have access to for build artifact storage.

These are the commands you can use...

- `./dev.sh build foo` -- compile only the lambda function `foo`
- `./dev.sh deploy` -- deploy the entire CloudFormation stack including all source code to the currently configured aws cli account.
- `./dev.sh upload foo` -- only replace the the code for the lambda function `foo`.
- `./dev.sh invoke foo bar.json` -- invoke and test the already deployed function `foo` with the input file `bar.json`.
- `./dev.sh delete` -- delete the entire CloudFormation stack and all resources.

### Adding a new lambda function

Add a new directory inside `src/lambdas` named after your function.  Inside there add a file `index.ts` if you're working in TypeScript or `index.js` if you're working in JavaScript.  The file must have an export function `handler` that will be called by AWS.

Add a new `AWS::Serverless::Function` resource inside `infrastructure/sam.yaml`.  Name it after your function with the first letter capitalized.  Set the `CodeUri` to be the dist zip file that will be generated.  eg: if your folder is `src/lambdas/fooBar` name your resource `FooBarFunction` with `CodeUri: ../dist/fooBar/fooBar.zip`.

## Continuous Integration

```
.
├── buildspec.yml
└── infrastructure
    ├── ci.yaml
    └── sam.yaml
```

Continuous integration is set up through another CloudFormation stack `infrastructure/ci.yaml`.  This stack defines a [CodePipeline](http://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html) that builds the project with [CodeBuild](http://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html), which runs the commands in `buildspec.yml`, and one of those commands deploys the SAM stack with CloudFormation.  It's a CloudFormation stack that deploys another CloudFormation stack!

Again, for clarity: `sam.yaml` defines the SAM stack that is the definition of all your lambda functions and their resources; `buildspec.yml` defines your compile and deploy commands; `ci.yaml` defines the CI stack that watches for git repo changes and redeploys the SAM stack automatically.

The CI stack itself **is not** deployed automatically on changes.  It must be deployed manually.  This was chosen to increase the effort necessary to attack the account.  The CI stack should rarely need to change.  For help manually deploying a CloudFormation stack see the relevant [AWS documentation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console.html). 

### Build secrets

You may run into a scenario where you need access to secrets during the build process.  For example you have a private repository of packages and need an SSH key to access them.

The best way to handle these secrets is store them in an S3 bucket, give the `CodeBuildServicePolicy` permission to read that bucket, and then use aws cli commands to retrieve the secrets.

For example add this to ci.yaml:
```yaml
# under CodeBuildServicePolicy.Properties.PolicyDocument.Statement
- Effect: Allow
  Action:
    - s3:GetObject
    - s3:ListBucket
  Resource:
    - !Sub "arn:aws:s3:::${MyBucketOfSecrets}"
    - !Sub "arn:aws:s3:::${MyBucketOfSecrets}/*"
  Principal:
    AWS: !GetAtt CiKeysAccessRole.Arn

# under CodeBuildProject.Properties.Environment.EnvironmentVariables
- Name: BUCKET_OF_SECRETS
  Value: !Ref MyBucketOfSecrets
```

and add this to buildspec.yml:

```yaml
# under phases.install.commands
- aws s3 sync s3://BUCKET_OF_SECRETS/ ~/secrets
```

### Setting up single stage CI

Single stage CI consists of only one CodePipeline.  A single branch is watched for changes.  When deploying for a single stage leave the `GitHubBranchDest` field empty.

The sequence of events goes like this:
- a pull request is merged into the master branch
- a git trigger causes CodePipeline to begin a release
- CodeBuild fetches the release from GitHub
- CodeBuild launches the build Docker image and runs the commands specified in `buildspec.yml`
- the output artifacts are stored in S3
- CloudFormation creates a change set for the SAM stack
- a developer approves the changeset
- CloudFormation executes the change set for the SAM stack

### Setting up two stage CI

Two stage CI consists of two CodePipelines.  The first CodePipeline watches a staging branch and deploys to a staging account.  After successfully deploying and testing in staging the code is merged into a prod branch where the process repeats in production.

The sequence of events goes like this:
- a pull request is merged into the staging branch
- a git trigger causes the *staging* CodePipeline to begin a release
- CodeBuild fetches the release from GitHub
- CodeBuild launches the build Docker image and runs the commands specified in `buildspec.yml`
- the output artifacts are stored in S3
- CloudFormation creates a change set for the SAM stack
- a developer approves the changeset
- CloudFormation executes the change set for the SAM stack on *staging*
- a lambda function creates and merges a pull request from the staging branch to the master branch
- a git trigger causes the *prod* CodePipeline to begin a release
- CodeBuild fetches the release from GitHub
- CodeBuild launches the build Docker image and runs the commands specified in `buildspec.yml`
- the output artifacts are stored in S3
- CloudFormation creates a change set for the SAM stack
- a developer approves the changeset
- CloudFormation executes the change set for the SAM stack on *prod*

### Contributors
- [Giftbit](https://github.com/Giftbit)
- [Jeffery Grajkowski](https://github.com/pushplay/)
- [Chris Pouliot](https://github.com/moxuz)
