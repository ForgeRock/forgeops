#!/usr/bin/env bash

# doc
read -r -d '' HELP << END

Quick api call script run an AM oauth login and api call to IDM supplying the transaction ids which can be used to search logs for full stack tracing. 
This script also attempts to set the X-ForgeRock-TransactionId header which should be removed by ingress.

ForgeRock Identity Platform API calls are documented on the "UI and API Access" page of the ForgeOps CDK documentation.
This script relies on using the CDK configuration for client ids and scopes.
This script makes no attempt to check that each API call is successful.
You can use use the transaction IDs to validate success.

Usage:
    check-txnid.sh fqdn password

Args:
    fqdn     fully qualified domain of ForgeRock Platform with no hanging /
    password amadmin password

Dependencies:
    jq
    python3
    column
    curl
END

usage() {
    printf "%-10s \n" "$HELP"
}

# this script is a heredoc that is used to get the "code" from the redirect login url
read -r -d '' PARSEURL <<'END'
import urllib.parse as p
import sys
try:
    print(p.parse_qs(p.urlparse(sys.argv[1]).query)["code"][0])
except:
    print("could not parse")
    sys.exit(1)
END

rqd() {
    if ! command -v $1 &> /dev/null;
    then                   
        echo "$1 required" 
        exit 1             
    fi                     
}

# validate deps that may commonly not be installed
rqd "jq"
rqd "curl"
rqd "python3"
rqd "column"

if ! command -v stern &> /dev/null;
then
    echo "stern is suggested to grep logs but not required"
fi

# the two required args
FQDN=${FQDN:-"unset"}
AMAPWD=${AMAPWD:-"unset"}

# make sure the vars are set via the environment or are arguments
if [[ $FQDN == "unset" ]] && [[ $AMAPWD == "unset" ]] && [[ $# -ne 2 ]];
      then
      usage
      exit 1
fi
# args overide env car
if [[ $# -eq 2 ]];
then
    FQDN=$1
    AMAPWD=$2
fi


# curl doesn't make it easy to parse both the response body and headers, so we write headers to a file
# this function pulls the transaction id out of the response header.
parseTxnId() {
    echo -n "$(grep x-forgerock-transactionid ${HEADERFILE} | awk -F ": " '{ print $2 }' | tr -d \\n\\r)"
}

# this is the temp file used to write headers to
# all curl calls overwrite this file so it's "short lived"
HEADERFILE=$(mktemp)
# clean up temp on exit
trap 'rm -f $HEADERFILE' EXIT

###########
# API Calls
###########
# all curl calls write to the header file and must have the txn id pulled before the next call
# all the curl calls attempt to force set the transaction id, these should be ignored.
###########

# this gets a token via the am admin user
tokenId=$(curl -s \
    -X POST \
    -D ${HEADERFILE} \
    -H "Content-Type: application/json" \
    -H "X-ForgeRock-TransactionId: YOUSHALLNOTPASS" \
    -H "X-OpenAM-Username: amadmin" \
    -H "X-OpenAM-Password: $AMAPWD" \
    -H "Accept-API-Version: resource=2.0, protocol=1.0" \
    "$FQDN/am/json/authenticate?realm=/" \
    | jq -r '.tokenId')
authid=$(parseTxnId)


# use the token id to authorize
authR=$(curl -X POST \
     --Cookie "iPlanetDirectoryPro=$tokenId" \
     -D ${HEADERFILE} -s \
     -H "X-ForgeRock-TransactionId: YOUSHALLNOTPASS" \
     -H "Accept-API-Version: resource=2.0, protocol=1.0"    \
     -d 'response_type=code' \
     -d 'client_id=idm-admin-ui' \
     -d "csrf=$tokenId" \
     -d 'scope=openid%20fr:idm:*' \
     -d 'state=123' \
     -d 'decision=allow' \
     -d "redirect_uri=$FQDN/platform/appAuthHelperRedirect.html" \
     $FQDN/am/oauth2/realms/root/authorize)

# this calls the python script from the top of the file with "location" field from the header which contains the "code" for doing an token exchange
# this should work on any python 3 install
code=$(python3 -c "$PARSEURL" $(grep -i location ${HEADERFILE} | awk -F ": " '{ print $2 }'))
# handle unparsable return values
if [ $? -ne 0 ]; then
    echo $code
    exit 1
fi
authorizeid=$(parseTxnId)

# run an token exchange
accessResponse=$(curl -X POST  \
     -D ${HEADERFILE} \
     -s \
     -d "code=$code" \
     -H "X-ForgeRock-TransactionId: YOUSHALLNOTPASS" \
     -d 'client_id=idm-admin-ui' \
     -d 'grant_type=authorization_code' \
     -d "redirect_uri=$FQDN/platform/appAuthHelperRedirect.html" \
     $FQDN/am/oauth2/realms/root/access_token)

accessToken=$(echo "${accessResponse}" | jq -r '.access_token')
exchangeid=$(parseTxnId)

# call idm  config endpoint
idmConfig=$(curl -s \
     -D ${HEADERFILE} \
     -H "Authorization: Bearer $accessToken" \
     -H "X-ForgeRock-TransactionId: YOUSHALLNOTPASS" \
     $FQDN/openidm/config)

configid=$(parseTxnId)

# pretty output of txn ids
column -t <<EOF
authid $authid
authzid $authorizeid
exchangetxnid $exchangeid
configtxnid $configid
shouldnotexistid YOUSHALLNOTPASS
EOF
echo ""
echo "stern -l 'app in (ds-cts,ds-idrepo,am,idm)' --since 5m | grep -e $authid -e $authorizeid -e $authorizeid -e $exchangeid -e  $configid"

