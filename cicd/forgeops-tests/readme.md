# Forgeops testing framework
Simple forgeops testing framework build on top of python3 unittest framework

## Building a docker image

```
docker build -t gcr.io/engineering-devops/forgeops-tests forgeops-tests
docker push  gcr.io/engineering-devops/forgeops-tests
```

## Configuration
To provide configuration you have to set following environmental variables for products

### AM
 - `AM_URL` : e.g. http://openam.default.forgeops.com/openam
 - 'AM_ADMIN_PWD' : AM admin password

### IDM
 - `IDM_URL` : IDM URL e.g. http://openidm.default.forgeops.com/openidm
 - `IDM_ADMIN_USERNAME` : IDM admin username, default is `openidm-admin`
 - `IDM_ADMIN_PWD` : IDM admin password, defaul is `openidm-admin`

### IG
 - `IG_URL` : IG URL, e.g. http://openig.default.forgeops.com


## Running tests.
For test developing purposes, it's possible to run tests directly from pycharm as it has integration for python unittest

To run tests from command line: `python3 forgeops-tests.py --suite [path to folder]`.
Folder is run recursively

Example: `python3 forgeops-tests.py --suite tests/smoke`

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
