# sam-scaffold
A template for a AWS SAM project with continuous integration.

[SAM](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md) is an extension of AWS's CloudFormation that makes it easier to define serverless applications.  It is unopinionated on language choice, build tools, or project layout.  This example project provides a set of opinions on those choices.  It can be cloned and used as is to get a serverless project up and running quickly, or it can be used as a guideline for your own project.

This project features:  TypeScript compilation, unit testing, CloudFormation templates, continuous integration.

## Source code

For the source code I highly recommend [TypeScript](https://www.typescriptlang.org/) although [ES2015](https://en.wikipedia.org/wiki/ECMAScript#6th_Edition_-_ECMAScript_2015) is also easily supported.

If you're only using TypeScript you can delete the `.babelrc` file and remove `babel-plugin-transform-async-to-generator` from `package.json`.

If you're only using ES2015 you can remove each of: `@types/*`, `ts-loader`, `ts-node`, `tslint` and `typescript` from `package.json`.


The actual compilation of the source code is controlled by [webpack](https://webpack.github.io/) which is configured in `webpack.config.js`.  It's configured here to use `index.ts` inside each directory in `src/lambdas` as an entry point.  It will compile all code reachable from that entry point into a single script inside `dist`.