# Forgeops smoke test suite
## Introduction
Basic smoke test suite to ensure products are deployed correctly.
Tests are simple shell scripts + curl.

In case of failure, scripts are exiting with RC 1 + error messages for
each test. This is useful in CICD systems like codefresh or simillar.

## Setup postcommit tests
Modify config.cfg to contain host and port for specific product.

## Tests
### AM
- Ping test
- Login test
- User login test

### DS
- TBD

### IDM
- Ping test
- Login test
- CRUD tests

### IG
- Ping test

## Run tests
To run tests simply execute `./forgeops-smoke-test.sh -l` to see list
of available tests. Select test you want to run and pass it as argument.

For example to run AM smoke test, execute `./forgeops-smoke-test.sh -s am-smoke.sh`
