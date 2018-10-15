# Tests and debugging
This document provides detailed test description and typical failures.

## Test descriptions
### AM tests
#### test_0_setup
*Set up a user for use with subsequent login testing.*

This test creates a user in AM that will be used later for login testing.

**Flow:**
 - Admin logs in
 - Admin creates user with POST request to: `json/realms/root/users/?_action=create`

**Problems seen previously:**
 - [1,2,3](#previously-seen-problems-with-am)

#### test_1_ping
*Test if OpenAM is responding on the isAlive.jsp endpoint*

**Flow:**
 - GET request to `/openam/isAlive.jsp`

**Problems seen previously:**
 - [2](#previously-seen-problems-with-am)

#### test_2_admin_login
*Test AuthN as amadmin*
**Flow:**
 - POST request to `openam/json/authenticate` with admin headers

**Problems seen previously:**
 - [2,3](#previously-seen-problems-with-am)

#### test_4_user_login
*Test AuthN as user*

**Flow:**
 - POST request to `openam/json/authenticate` with admin headers

**Problems seen previously:**
 - [1,2,3](#previously-seen-problems-with-am)

#### test_5_oauth2_access_token
*Test OAuth2 access token*

**Flow:**
 - Testuser logs in using POST to `openam/json/authenticate`
 - Testuser initiates OAuth2 authz to `openam/oauth2/authorize`
 - Extract authentication code from redirect URL
 - Exchange code for access token

**Problems seen previously:**
 - [1,2,3,4](#previously-seen-problems-with-am)

#### Problems seen previously with AM:

Problems:
 1. **Userstore not reachable**: Run `kubectl -n=smoke get pods` to check that the userstore is running and passed live check (1/1).

 2. **AM not reachable**: Ensure you can get to the openam.smoke.forgeops.com/openam/ page in a browser. If not, try to get logs from
 the openam pod using `kubectl -n=smoke logs <am_podname>`. Also, getting the pod description might point you to problems - run `kubectl -n=smoke describe pod <am_podname>`

 3. **Wrong CTS config**: Previously, we have seen that after updating config, CTS was not reachable due to wrong CTS configuration - admin was not able to login and create user.
 Look at the AM logs to see if there are any indication of CTS connection failures.

 4. **Missing secret keys in keystore**: Given we are providing the keystore as part of the Helm chart, it's not updated automatically. When bumping the version, there might be problem with an old keystore.


Common AM problems:
 - **Amster import errors**: When we are bumping the product version, it's important to check to see if there are any import failures. When there are failures, we need to deploy AM using an empty import, and then export these failed imports again. There is a known bug with site.json exporting an id field, which can't be re-imported.

### IDM tests
The IDM tests are expecting an additional couple of modifications in config(bi-dir sync with LDAP). They are:
 - Enabled self-service registration
 - Enabled self-service password reset

It's important to keep in mind to manage these changes when updating configs. Specifically these files:
 - ui-configuration.json (enabled registration & pw reset)
 - selfservice.kba.json (1 question, 1 minimum)


#### test_0_ping
*Pings OpenIDM to see if server is alive using admin headers*

**Flow:**
 - GET request to `openidm/info/ping` with admin headers

**Problems seen previously:**
- [1,2](#previously-seen-problems-with-idm)

#### test 1,2,4,5 (Create, update, login/read, delete)
*Managed user operations as admin*

**Flow:**
 - Single call to `managed/user` endpoint with admin headers

**Problems seen previously:**
 - [1,2](#previously-seen-problems-with-idm)


#### test_3_run_recon_to_ldap
*Test to run reconciliation to ldap*

**Flow:**
 - POST request to `/recon` with admin headers

**Problems seen previously:**
 - [1,2,3](#previously-seen-problems-with-idm)

#### test_6_user_self_registration
*Test to use self service registration as user*

*NOTE: test is recreating the same requests that the IDM UI does when a user performs self-service*

**Flow:**
 1. POST to self-reg endpoint, extract token as anonymous
 2. POST to self-reg endpoint, with token and json body as anonymous

**Problems seen previously:**
 - [1,2,3](#previously-seen-problems-with-idm)

#### test_7_user_reset_pw
*Test to use self service password reset as user*

*NOTE: user changing password is created in the previous step. If self-reg fails, this test
will too.*

**Flow:**
 1. POST to pw reset endpoint, extract token as anonymous
 2. POST to pw reset endpoint, add search filter for user
 3. POST to pw reset, stage 2 - Answer security question
 4. POST to pw reset, stage 3 - Change password

 **Seen problems:**
  - [1,2,3](#previously-seen-problems-with-idm)

#### Problems seen previously with IDM
 1. **Config errors**: There are compatibility problems when bumping the version. Logs from IDM pod usually shows these errors.
 2. **Repo scheme errors**: The smoke tests use Postgres as the base repo. A couple of times, we've seen the scripts to configure the DB have changed - it's important to keep it up-to-date. To verify that the scripts are up to date, review the `forgeops/helm/postgres-openidm/sql` directory and compare the scripts there with the IDM repo init scripts(`openidm.zip/db/postgresql/scripts`). Make sure that you are comparing the same IDM revisions.
 3. **Userstore not reachable**: Reconciliation might fail when the userstore is not ready. Check the userstore pod to verify it's  ready.


### IG tests

Currently there is only ping test for IG, which checks to see if the landing page is accessible.
In case of a failure, check common failures.


## Common failures
This is an unordered list of deployment failures or problems we've seen previously.
In case something is not working in your environment, check for following things:

 - Docker images are not downloaded - check with `kubectl describe pod <product pod>` and look for:
   - Wrong tag
   - Repository not accessible
   - Wrong image name  
 - Products are restarted/keeps restarting:
   - Sometimes products might be restarted as we are using a preemptible cluster.
   - There is an error that prevents the product from starting up correctly. Check log messages from product pods.
 - Configuration is not applied:
  - Check git & product logs
