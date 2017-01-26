# sam-scaffold
A template for an AWS SAM project with continuous integration.

[SAM](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md) is an extension of AWS's CloudFormation that makes it easier to define serverless applications.  It is unopinionated on language choice, build tools, or project layout.  This example project provides a set of opinions on those choices.  It can be cloned and used as is to get a serverless project up and running quickly, or it can be used as a guideline for your own project.

This project features:  TypeScript or ES2015 compilation, linting, unit testing, CloudFormation templates, continuous integration.

## Source code

Two versions are provided: one with a [TypeScript](https://www.typescriptlang.org/) code base and another with JavaScript ([ES2015](https://en.wikipedia.org/wiki/ECMAScript#6th_Edition_-_ECMAScript_2015) specifically).  I highly recommend the TypeScript version, but the choice is yours.

## Development

```
.
├── dev.sh
├── infrastructure
│   └── sam.yaml
└── src
    └── lambdas
        └── ...
```

The behaviour of a lambda function is determined by its source code (inside `src/lambdas`) and the other serverless resources it has access to (inside the CloudFormation template `infrastructure/sam.yaml`).

### Building

Compile the project with: `npm run build`.

Each lambda function will be built separately and packaged with its dependencies in a zip file in `dist`.  For example `src/lambdas/myfxn` will be packaged in `dist/myfxn/myfxn.zip`.  Don't worry about unnecessary libraries in node_modules being included.  Only the source code referenced will be included.

### Deployment

Deploying to a development account is easily done with the included script `dev.sh`.  The script requires the [aws cli](https://aws.amazon.com/cli/) installed and configured for a development account.  For security reasons this should not be your production account.  It also requires bash, which is a useful tool even on [Windows](http://stackoverflow.com/questions/36352627/how-to-enable-bash-in-windows-10-developer-preview).
 
Edit the top of `dev.sh` and replace `STACK_NAME` with a name that describes the project and replace `BUILD_ARTIFACT_BUCKET` with the name of an S3 bucket you have access to for build artifact storage.

These are the commands you can use...

- `./dev.sh build foo` -- compile only the lambda function `foo`
- `./dev.sh deploy` -- deploy the entire CloudFormation stack including all source code to the currently configured aws cli account.
- `./dev.sh upload foo` -- only replace the only the code for the lambda function `foo`.
- `./dev.sh invoke foo bar.json` -- invoke and test the already deployed function `foo` with the input file `bar.json`.
- `./dev.sh delete` -- delete the entire CloudFormation stack and all resources.

### Linting

Linting is running a program that checks the source code for potential style and logical problems.  The linter is set up to be run with: `npm run lint`.

Linting is provided by [ESLint](http://eslint.org/) in JavaScript and [TSLint](https://palantir.github.io/tslint/) in TypeScript.  Check out their documentation for adjusting the rules to suit your preferred style.

### Unit testing

Unit testing is provided by [Mocha](https://mochajs.org/) and [Chai](http://chaijs.com/) and is run with: `npm run test`.  

### Adding a new lambda function

Add a new directory inside `src/lambdas` named after your function.  Inside there add a file `index.ts` if you're working in TypeScript or `index.js` if you're working in JavaScript.  The file must have an export function `handler` that will be called by AWS.

Add a new `AWS::Serverless::Function` resource inside `infrastructure/sam.yaml`.  Name it after your function with the first leter capitalized.  Set the `CodeUri` to be the dist zip file that will be generated.  eg: if your folder is `src/lambdas/fooBar` name your resource `FooBarFunction` with `CodeUri: ../dist/fooBar/fooBar.zip`.

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

The CI stack is configured by default to use a standard node [Docker](https://www.docker.com/) image.  It can be configured instead to use a custom Docker image.  See the `AWS::CodeBuild::Project` resource in `ci.yaml` for the relevant property.  `infrastructure/ciDockerImage` contains a helpful script and `Dockerfile` for building and uploading the custom image.

`buildspec.yml` defines the commands run to build the project inside the Docker image.  By default it runs `npm run build` and won't need to change for most projects.

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

## Contributors
- [Giftbit](https://github.com/Giftbit)
- [Jeffery Grajkowski](https://github.com/pushplay/)
