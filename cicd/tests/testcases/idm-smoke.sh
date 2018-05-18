#!/usr/bin/env bash
################################################################################
# ForgeOps IDM smoke tests definitions
#
# This suite cointains a set of smoke tests that are intended to be run
# as part of CI/CD process.
#
# To run this tests, run ../forgeops-smoke-tests.sh -s am_smoke.sh
#
# Each testcase is going to be described inline
#
# Each test must set PASS=true/false and optionally RES with content that
# will be logged in out.txt
#
################################################################################

# Testcase definitions


# Ping test - using admin credentials, curl to /info/ping, expect HTTP-200
ping_test() {
  TESTNAME="IDM ping test"
  echo $IDM_URL
  RES=$(curl -v -u openidm-admin:$IDM_ADMIN_PWD $IDM_URL/info/ping \
          -o /dev/null -w '%{http_code}\n' -s)
  if [ "$RES" = "200" ]; then
    PASS=true
  fi
}

# Create managed user. Expect HTTP-201
create_managed_user() {
  TESTNAME="IDM Create managed user"
  RES=$( curl --header "X-OpenIDM-Username: openidm-admin" \
    --header "X-OpenIDM-Password: openidm-admin" \
    --header "Content-Type: application/json" \
    --header "if-none-match: *" --data '{"userName": "forgeops-testuser", "telephoneNumber": "6669876987", "givenName": "devopsguy", "description": "Just another user", "sn": "sutter", "mail": "rick@example.com", "password": "Th3Password", "accountStatus":"active"}' \
    --request PUT "$IDM_URL/managed/user/forgeops-testuser" \
    -o /dev/null -w '%{http_code}\n' -s)

  if [[ $RES = "201" ]]; then
    PASS=true
  else
    PASS=false
  fi
}

# Update previously created user, expect HTTP-200
update_managed_user() {
  TESTNAME="IDM Update managed user"
  RES=$( curl --header "X-OpenIDM-Username: openidm-admin" \
    --header "X-OpenIDM-Password: $IDM_ADMIN_PWD" \
    --header "Content-Type: application/json" \
    --header "if-match: *" \
    --data '{"userName": "forgeops-testuser", "telephoneNumber": "6669876987", "givenName": "devopsguy", "description": "Just another user", "sn": "sutter", "mail": "rick@example.com", "password": "Th3RealPassword", "accountStatus":"active"}' \
    --request PUT "$IDM_URL/managed/user/forgeops-testuser" \
    -o /dev/null -w '%{http_code}\n' -s)

  if [[ $RES = "200" ]]; then
    PASS=true
  else
    PASS=false
  fi
}

# Run reconciliation from default IDM store -> external LDAP, expect HTTP-200
run_recon_to_ldap() {
  TESTNAME="IDM Run recon to ldap"
  RES=$( curl --header "Content-Type: application/json" \
    --header "X-OpenIDM-Password: openidm-admin" \
    --header "X-OpenIDM-Username: $IDM_ADMIN_PWD"  \
    --request POST "$IDM_URL/recon?_action=recon&mapping=managedUser_systemLdapAccounts&waitForCompletion=True" \
    -o /dev/null -w '%{http_code}\n' -s)

  if [[ $RES = "200" ]]; then
    PASS=true
  else
    PASS=false
  fi
}

# Login as user, expect HTTP-200
login_managed_user() {
  TESTNAME="IDM Login managed user"
  RES=$( curl --header "X-OpenIDM-Username: forgeops-testuser" \
    --header "X-OpenIDM-Password: Th3RealPassword" \
    --header "Content-Type: application/json"  \
    --request GET "$IDM_URL/info/ping" \
    -o /dev/null -w '%{http_code}\n' -s)

  if [[ $RES = "200" ]]; then
    PASS=true
  else
    PASS=false
  fi
}

# Delete created user, expect HTTP-200
delete_managed_user() {
  TESTNAME="IDM Delete managed user"
  RES=$( curl --header "X-OpenIDM-Username: openidm-admin" \
    --header "X-OpenIDM-Password: $IDM_ADMIN_PWD" \
    --header "Content-Type: application/json" \
    --header "if-match: *" \
    --request DELETE "$IDM_URL/managed/user/forgeops-testuser" \
    -o /dev/null -w '%{http_code}\n' -s)

  if [[ $RES = "200" ]]; then
    PASS=true
  else
    PASS=false
  fi
}



# Package funtions
tests=(
  ping_test
  create_managed_user
  update_managed_user
  run_recon_to_ldap
  login_managed_user
  delete_managed_user
)
