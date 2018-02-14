#!/usr/bin/env bash
# Create the metrics user for monitoring.
#
cd /opt/opendj
source /opt/opendj/env.sh

MONITOR_PASSWORD=password

# Create the metrics user ldif:
cat  <<EOF > /tmp/metrics.ldif
dn: cn=metrics
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
givenName: Directory
sn: Monitor
ds-pwp-password-policy-dn: cn=Root Password Policy,cn=Password Policies,cn=config
ds-privilege-name: monitor-read
cn: metrics
userPassword: $MONITOR_PASSWORD
EOF


# This batch file:
# - Creates a identity mapper that maps the http basic auth user name to the backend metrics user
# - Creates a new basic auth mechanism that uses the mapper
# - Creates an http connection handler for the metrics endpoint
# - Sets the endpoint auth mechanism
# - Creates a new backend for the metrics user to live in
bin/dsconfig  -h localhost -p 4444 -D "cn=directory manager" \
    -w ${PASSWORD} --trustAll \
    --no-prompt --batch <<EOF
create-identity-mapper --mapper-name "CN Match" --type exact-match --set enabled:true --set match-attribute:cn \
   --set match-base-dn:"cn=metrics"
create-http-authorization-mechanism --set enabled:true --set identity-mapper:CN\ Match  \
   --type http-basic-authorization-mechanism --mechanism-name BasicAuthCNMatch
create-connection-handler --type http --handler-name "Metrics Handler" --set enabled:true --set listen-port:8081
set-http-endpoint-prop --endpoint-name /metrics/prometheus --set authorization-mechanism:BasicAuthCNMatch
create-backend --backend-name metrics  --type ldif  --set enabled:true \
   --set base-dn:cn=metrics  --set ldif-file:db/metricsUser.ldif  --set is-private-backend:true
EOF

# Import the ldif into the new backend.
bin/ldapmodify -D "cn=Directory Manager"  -h $HOSTNAME -p 1389 -w "${PASSWORD}" -f /tmp/metrics.ldif

# To test this:
# curl -v --user "metrics:password"  http://localhost:8081/metrics/prometheus