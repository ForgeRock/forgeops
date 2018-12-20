# Forgeops testing framework
Simple forgeops testing framework build on top of python3 unittest framework

## Deploy the products before
Testing framework assumes products are already running

You can find below two examples : 
- [Deploy in google cloud] 

<b>OR</b>
- [Building a docker image]
### Deploy in google cloud
Assuming you have access and permission.

Example : deploy products using *samples/config/smoke-deployment* configuration
#### Set your custom namespace 
deploy.sh script will use NAMESPACE value. Select a custom one to avoid conflicts.
```--- a/samples/config/smoke-deployment/env.sh
+++ b/samples/config/smoke-deployment/env.sh
@@ -1,7 +1,7 @@
# Environment settings for the deployment

# k8s namespace to deploy in
-NAMESPACE=smoke
+NAMESPACE=my_name_space

# Top level domain. Do not include the leading .
DOMAIN="forgeops.com"
```

#### Deploy products
`$ bin/deploy.sh samples/config/smoke-deployment/`

You can now go to [Configuration] chapter

### Building a docker image

```
docker build -t gcr.io/engineering-devops/forgeops-tests forgeops-tests
docker push  gcr.io/engineering-devops/forgeops-tests
```

## Configuration
To provide configuration you have to set following environmental variables for products

### AM
 - `AM_URL` : e.g. http://login.default.forgeops.com/
 - 'AM_ADMIN_PWD' : AM admin password

### IDM
 - `IDM_URL` : IDM URL e.g. http://openidm.default.forgeops.com/openidm
 - `IDM_ADMIN_USERNAME` : IDM admin username, default is `openidm-admin`
 - `IDM_ADMIN_PWD` : IDM admin password, defaul is `openidm-admin`

### IG
 - `IG_URL` : IG URL, e.g. http://openig.default.forgeops.com


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
`python3 forgeops-tests.py --suite [path to folder]`
Folder is run recursively

Example: `python3 forgeops-tests.py --suite tests/smoke`

## Example to deploy and run the test
```
#!/usr/bin/env bash

MY_CONFIG="samples/config/smoke-deployment"
MY_NAMESPACE="my_name_space"
cd forgeops
if [ $? -ne 0 ] ; then
    echo "ERROR : can not go into forgeops workspace"
    exit
fi
echo "NAMESPACE : ${MY_NAMESPACE}"
echo "CONFIG    : ${MY_CONFIG}"

echo ""
echo "Deploy products ${MY_NAMESPACE}"
sed -i.bak s/NAMESPACE=smoke/NAMESPACE=${MY_NAMESPACE}/g ${MY_CONFIG}/env.sh
bin/deploy.sh ${MY_CONFIG}

echo ""
echo "Configure"
AM_URL=http://login.${MY_NAMESPACE}.forgeops.com/
IG_URL=http://openig.${MY_NAMESPACE}.forgeops.com
IDM_URL=http://openidm.${MY_NAMESPACE}.forgeops.com/openidm
echo "export AM_URL=${AM_URL}"
export AM_URL=${AM_URL}
echo "export IDM_URL=${IDM_URL}"
export IDM_URL=${IDM_URL}
echo "export IG_URL=${IG_URL}"
export IG_URL=${IG_URL}

echo ""
echo "Run tests"
cd cicd/forgeops-tests/
./install-deps.sh
python3 forgeops-tests.py --suite tests/smoke
cd -

echo ""
echo "To remove all run command : bin/remove-all.sh -N ${MY_NAMESPACE}"
```

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
