#!/usr/bin/env bash
set -e

DJ_HOME="${DJ_HOME:-/opt/opendj}"
DUR="${2:-60}"
HOST="${3:-ds-idrepo-0.ds-idrepo}"
USERS="${4:-1000000}"
BASE_DN="${BASE_DN:-ou=identities}"

export OPENDJ_JAVA_ARGS="-Xmx512m"

ADMIN_PW=${ADMIN_PW:-password}


srch() {

    echo ""
    echo "Starting searchrate on ${BASE_DN} with a range of ${USERS} random users..."
    $DJ_HOME/bin/searchrate --hostname ${HOST} --port 1389 \
        --bindDn "uid=admin" \
        --bindPassword "${ADMIN_PW}" \
        --warmUpDuration 10 \
        --noRebind \
        --numConnections 64 \
        --numConcurrentRequests 8 \
        --maxDuration ${DUR} \
        --baseDn ${BASE_DN} \
        --argument "rand(0,${USERS})" "(uid=user.{})"
}


mod() {

    echo ""
    echo "Starting modrate on ${BASE_DN} with a range of ${USERS} random users..."
    $DJ_HOME/bin/modrate --hostname ${HOST} --port 1389 \
         --bindDn "uid=admin" \
         --bindPassword "${ADMIN_PW}" \
         --noRebind \
         --numConnections 8 \
         --maxDuration ${DUR} \
         --targetDn "uid=user.{1},ou=people,${BASE_DN}" \
         --argument "rand(0,${USERS})" \
         --argument "randstr(16)" 'description:{2}'

}

auth() {
    echo ""
    echo "Starting authrate on ${BASE_DN} with a range of ${USERS} random users..."
    $DJ_HOME/bin/authrate --hostname ${HOST} --port 1389 \
         --bindDn "uid=admin" \
         --bindPassword "${ADMIN_PW}" \
         --keepConnectionsOpen \
         --numConnections 20 \
         --maxDuration ${DUR} \
         --baseDN "${BASE_DN}" \
         --searchScope sub \
         --argument "rand(0,${USERS})" "(uid=user.{})"

}


genctstemplate() {

echo "Generating CTS template..."

cat >/tmp/cts.template  <<EOF
define suffix=ou=tokens

branch: [suffix]
subordinateTemplate: coreToken

template: coreToken
rdnAttr: coreTokenId
coreTokenId: <random:hex:13>_<random:hex:3>_<random:hex:8>
objectClass: top
objectClass: frCoreToken
coreTokenString09: clientOIDC_0
coreTokenObject: \[\{"g":"{coreTokenId}.<random:hex:27>","_s":["openid"],"r":"{coreTokenId}.<random:hex:27>","rx":"1522747004911","rgt":"authorization_code","rtt":"Bearer","rtn":"refresh_token","rati":"<random:hex:8>-<random:hex:4>-<random:hex:4>-<random:hex:4>-<random:hex:12>-<random:hex:4>","_at":1522157123,"_al":0,"_u":"http://example.com","_am":"DataStore","_acr":"0","gt":\[\]\}\]
coreTokenExpirationDate: 20180328112709.803+0100
coreTokenType: OAUTH2_GRANT_SET
coreTokenString08: myrealm
coreTokenString03: user.<random:numeric:0:100000>
EOF

}


add() {
    TEMPLATE="config/MakeLDIF/addrate.template"

    if [ "$1" == "cts" ]; then
        genctstemplate
        TEMPLATE="/tmp/cts.template"
        BASE_DN="o=cts"
    fi


    #  deleteMode can be "off", "fifo" or "random"
    #  if it is "on" the add  --deleteSizeThreshold 1000
    echo ""
    echo "Starting addrate on ${BASE_DN}..."
    $DJ_HOME/bin/addrate --hostname ${HOST} --port 1389 \
          --bindDN "uid=admin" \
          --bindPassword "${ADMIN_PW}"  \
          --noRebind \
          --numConnections 8 \
          --numConcurrentRequests 1 \
          --deleteMode off \
          --maxDuration ${DUR}  \
          ${TEMPLATE}

}

mixed () {
  echo "TBD"
}


# Main


case "$1" in

      srch|search)
      	srch
      	;;

      mod|modify)
     	mod
      	;;

      auth|authn)
      	auth
      	;;

      add)
     	add
      	;;

      mix)
        mixed
      	;;

      addcts)
        add "cts"
        ;;

      all)
      	srch
    	mod
    	auth
    	add
      	;;
      *)
      	echo "Usage: ds_bench srch|mod|auth|add|addcts|mix|all <duration in sec> <hostname> <users>"
      	;;

esac
