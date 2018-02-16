#!/usr/bin/env bash

cd /opt/opendj
source /opt/opendj/env.sh


# curl -v --user "user.0:password" http://localhost:8080/api/users/user.0
# Create HTTP rest2ldap handler on port 8080
bin/dsconfig  \
  --hostname $HOSTNAME  --port 4444  \
  --no-prompt  --trustAll \
  --bindDN "cn=Directory Manager"  --bindPasswordFile $DIR_MANAGER_PW_FILE  --batch <<EOF
create-connection-handler --handler-name HTTP  --type http --set enabled:true  --set listen-port:8080
set-http-endpoint-prop --endpoint-name /api --set authorization-mechanism:"HTTP Basic" --set config-directory:config/rest2ldap/endpoints/api --set enabled:true
EOF
