# sam-scaffold TypeScript

Included are two example lambda functions: `helloWorld` which does all the incredible things you expect from that name, and `robots` which implements a simple CRUD REST API using [Cassava](https://github.com/Giftbit/cassava/).

## Linting

Linting is running a program that checks the source code for potential style and logical problems.  The linter is set up to be run with: `npm run lint`.

Linting is provided by [ESLint](http://eslint.org/) with a [TypeScript plugin](https://typescript-eslint.io/).  Check out the documentation for adjusting the rules to suit your preferred style.

## Unit testing

Unit testing is provided by [Mocha](https://mochajs.org/) and [Chai](http://chaijs.com/) and is run with: `npm run test`.
 
Test files are located next to the file being tested with the extension `.test.ts`.  eg: `index.ts` is beside test file `index.test.ts`.  Just like libraries not referenced by index.ts WebPack will not include these files in the distribution.
