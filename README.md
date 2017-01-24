# sam-scaffold
A template for a AWS SAM project with continuous integration.

[SAM](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md) is an extension of AWS's CloudFormation that makes it easier to define serverless applications.  It is unopinionated on language choice, build tools, or project layout.  This example project provides a set of opinions on those choices.  It can be cloned and used as is to get a serverless project up and running quickly, or it can be used as a guideline for your own project.

This project features:  TypeScript compilation, unit testing, CloudFormation templates, continuous integration.

## Source code

Two versions are provided: one with a [TypeScript](https://www.typescriptlang.org/) code base and another with JavaScript ([ES2015](https://en.wikipedia.org/wiki/ECMAScript#6th_Edition_-_ECMAScript_2015) specifically).  I highly recommend the TypeScript version, but the choice is up to you.

## Development

```
.
├── infrastructure
│   └── sam.yaml
└── src
    └── lambdas
        └── ...
```

The behaviour of a lambda function is determined by its source code (inside `src/`) and the other serverless resources it has access to (inside the CloudFormation template `infrastructure/sam.yaml`).

### The commands

Local development should be done with [aws cli](https://aws.amazon.com/cli/) installed and configured to use a development account.  For security reasons this should not be your production account.

Development is made easier with these commands:

- `npm run build` -- compile all lambda functions.
- `npm run test` -- run all unit tests.
- `./build.sh foo` -- compile only the lambda function `foo`
- `./deploy.sh` -- deploy the entire CloudFormation stack including all source code to the currently configured aws cli account.
- `./upload.sh foo` -- only replace the only the code for the lambda function `foo`.
- `./invoke.sh foo bar.json` -- invoke and test the already deployed function `foo` with the input file `bar.json`.

### Unit testing

Unit testing is done with [Mocha](https://mochajs.org/) and [Chai](http://chaijs.com/).  

### Adding a new lambda function

Add a new directory inside `src/lambdas` named after your function.  Inside there add a file `index.ts` if you're working in TypeScript or `index.js` if you're working in JavaScript.  The file must have an export function `handler` that will be called by AWS.

## Continuous Integration

```
.
├── buildspec.yml
└── infrastructure
    ├── ci.yaml
    ├── ciDockerImage
    │   ├── Dockerfile
    │   └── build.sh
    └── sam.yaml
```

Continuous integration is set up through another CloudFormation stack `infrastructure/ci.yaml`.  This stack defines a [CodePipeline](http://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html) that builds the project with [CodeBuild](http://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html) and deploys the SAM stack with CloudFormation.  It's a CloudFormation stack that deploys another CloudFormation stack!

Again, for clarity: `sam.yaml` defines the SAM stack that is the definition of all your lambda functions and their resources; `ci.yaml` defines the CI stack that watches for git repo changes and redeploys the SAM stack automatically.
 
The CI stack is not deployed automatically on changes.  It must be deployed manually.  This was chosen to increase the effort necessary to attack the account.  The CI stack should rarely need to change anyways.

The one reason the CI stack would need to change is if the SAM stack is now defining a new resource that the CI stack needs permission to create.  In that case you will need to add the permission, redeploy the CI stack, and then trigger another build to have it attempt to deploy the SAM stack.

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
