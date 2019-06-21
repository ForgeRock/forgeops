# Forgeops testing framework
Simple forgeops testing framework build on top of python3 unittest framework

## Deploy the products before
Testing framework assumes products are already running

## Configuration
To provide configuration you have to set following environmental variables for products

### ALL
 - `TESTS_NAMESPACE` : default is `smoke`
 - `TESTS_DOMAIN` : default is `forgeops.com`

### AM
 - 'AM_ADMIN_PWD' : AM admin password

### IDM
 - `IDM_ADMIN_USERNAME` : IDM admin username, default is `openidm-admin`
 - `IDM_ADMIN_PWD` : IDM admin password, default is `openidm-admin`

## Running tests

### Prerequisites
#### Install dependencies
```
cd forgeops/cicd/forgeops-tests
./install-deps.sh
```
### Run the tests
#### Through pycharm
For test developing purposes, it's possible to run tests directly from pycharm as it has integration for python unittest
#### Through command line
`python3 forgeops-tests.py [path to folder]`
Folder is run recursively

Example: `python3 forgeops-tests.py tests/smoke`


## Getting results
Results from runs are stored in reports folder.

## Developing tests
In case you want add custom testcases, you need to do following:

 - Create a custom folder for tests in tests folder
 - Create a testclass with extending unittest.TestCase e.g `class AMFailoverTest(unittest.TestCase)``
 - Load a config into class
    ```
    from config.ProductConfig import AMConfig
    ...
    ...
    amcfg = AMConfig()
    ```
 - Each test method must start with `test_` method name
