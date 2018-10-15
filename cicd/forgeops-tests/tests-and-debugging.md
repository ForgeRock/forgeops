# Tests and debugging
Following document hopes to provide detailed tests description along with usually observed failures.

## Test descriptions
### AM tests
#### test_0_setup
*Setup a user that will be tested in user login.*

This test creates user in AM that will be later used for login tests.

**Flow:**
 - Admin logs in
 - Admin creates user with POST request to: `json/realms/root/users/?_action=create`

**Seen problems:**
 - [1,2,3](#previously-seen-problems-with-am)

#### test_1_ping
*Test if OpenAM is responding on isAlive.jsp endpoint*

**Flow:**
 - GET request to `/openam/isAlive.jsp`

**Seen problems:**
 - [2](#previously-seen-problems-with-am)

#### test_2_admin_login
*Test AuthN as amadmin*
**Flow:**
 - POST request to `openam/json/authenticate` with admin headers

**Seen problems:**
 - [2,3](#previously-seen-problems-with-am)

#### test_4_user_login
*Test AuthN as user*

**Flow:**
 - POST request to `openam/json/authenticate` with admin headers

**Seen problems:**
 - [1,2,3](#previously-seen-problems-with-am)

#### test_5_oauth2_access_token
*Test Oauth2 access token*

**Flow:**
 - Testuser login using POST to `openam/json/authenticate`
 - Testuser initiate Oauth2 authz to `openam/oauth2/authorize`
 - Extract authentication code from redirect url
 - Exchange code for access token

**Seen problems:**
 - [1,2,3,4](#previously-seen-problems-with-am)

#### Previously seen problems with AM

Problems:
 1. **Userstore not reachable**: `kubectl -n=smoke get pods` to check if userstore is running and passed live check (1/1)

 2. **AM not reachable**: Ensure you can get to openam.smoke.forgeops.com/openam/ page in browser. If not, try to get logs from
 openam pod `kubectl -n=smoke logs <am_podname>`. Also getting pod description might point you to problems `kubectl -n=smoke describe pod <am_podname>`

 3. **Wrong CTS config**: We previously seen that after updating config, CTS was not reachable due to wrong CTS configuration - admin was not able to login and create user.
 Look into am logs if there are any indication of CTS connection failures

 4. **Missing secret keys in keystore**: Given we are providing keystore as part of helm chart, it's not updated automatically. When bumping version, there might be problem with old keystore.


Common AM problems:
 - **Amster import errors**: When we are bumping product version, it's important to check if there are any import failures. When there are failures, we need to deploy AM with empty import and export these failed imports again. There is also one bug with site.json exporting id field which can't be imported back.

### IDM tests
IDM tests are expecting additional couple of modifications in config(bi-dir sync with LDAP). They are:
 - Enabled self-service registration
 - Enabled self-service password reset

It's important to keep in mind to manage these changes when updating configs. Specifically these files:
 - ui-configuration.json (enabled registration & pw reset)
 - selfservice.kba.json (1 question, 1 minimum)


#### test_0_ping
*Pings OpenIDM to see if server is alive using admin headers*

**Flow:**
 - GET request to `openidm/info/ping` with admin headers

**Seen problems:**
- [1,2](#previously-seen-problems-with-idm)

#### test 1,2,4,5 (Create, update, login/read, delete)
*Managed user operations as admin*

**Flow:**
 - Single call to `managed/user` endpoint with admin headers

**Seen problems:**
 - [1,2](#previously-seen-problems-with-idm)


#### test_3_run_recon_to_ldap
*Test to run reconciliation to ldap*

**Flow:**
 - POST request to `/recon` with admin headers

**Seen problems:**
 - [1,2,3](#previously-seen-problems-with-idm)

#### test_6_user_self_registration
*Test to use self service registration as user*

*NOTE: test is recreating same requests as IDM UI is doing when user perform self-service*

**Flow:**
 1. POST to self-reg endpoint, extract token as anonymous
 2. POST to self-reg endpoint, with token and json body as anonymous

**Seen problems:**
 - [1,2,3](#previously-seen-problems-with-idm)

#### test_7_user_reset_pw
*Test to use self service password reset as user*

*NOTE: user changing password is created in previous step. If self reg fails, this test
will too.*

**Flow:**
 1. POST to pw reset endpoint, extract token as anonymous
 2. POST to pw reset endpoint, add search filter for user
 3. POST to pw reset, stage 2 - Answer security question
 4. POST to pw reset, stage 3 - change password

 **Seen problems:**
  - [1,2,3](#previously-seen-problems-with-idm)

#### Previously seen problems with IDM
 1. **Config errors**: There are compatibility problems when bumping version. Getting logs from IDM pod usually displays these errors.
 2. **Repo scheme errors**: Smoke tests are using postgres as base repo. We've seen couple of times that scripts to configure DB are changing and it's important to keep it up to date. To check if scripts are up to date, look into `forgeops/helm/postgres-openidm/sql` and compare these with IDM repo init scripts(`openidm.zip/db/postgresql/scripts`). ! Make sure you are comparing same IDM revisions.
 3. **Userstore not reachable**: When doing reconciliation, it might fail when userstore is not ready. Check for pods if userstore is ready.


### IG tests

Currently there is only ping test for IG which checks if landing page is accessible.
In case of failure, check common failures.


## Common failures
This is unordered list deployment failures or problems we've seen previously
In case something is not working in your environment, check for following things:

 - Docker images are not downloaded(check with `kubectl describe pod <product pod>`):
   - Wrong tag
   - Repository not accessible
   - Wrong image name  
 - Products are restarted/keeps restarting:
   - Sometimes products might be restarted as we are using preemptible cluster.
   - There is error which prevents from product to start up correctly. Check log messages from product pods
 - Configuration is not applied:
  - Check git & product logs
