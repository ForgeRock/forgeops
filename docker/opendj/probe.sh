#!/usr/bin/env sh
# Sample shell script to check for readiness
# Returns 0 on ready, non zero if DJ is not ready
#DEBUG="-v"

exec ldapsearch $DEBUG -y ${DIR_MANAGER_PW_FILE} -H ldap://localhost:389 -D "cn=Directory Manager" -s base -l 5
