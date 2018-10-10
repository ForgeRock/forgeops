# Test and debugging
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
TODO

## Common failures
TODO
## Per product failures
TODO 
### AM
