#!/usr/bin/env sh
# Sample shell script to check for readiness and liveness.
# Returns 0 on ready, non zero if DJ is not ready
#DEBUG="-v"

# If bootstrapping is in progress, we are not ready.
if [ -f /opt/opendj/BOOTSTRAPPING ]; 
then 
    exit 1
fi
# Else - query the ldap server
# Asking for the 1.1. attribute returns only the dn - cuts down on traffic
exec ldapsearch $DEBUG -y ${DIR_MANAGER_PW_FILE} -H ldap://localhost:1389 -D "cn=Directory Manager" -s base -l 5 "(objectClass=*)" 1.1
