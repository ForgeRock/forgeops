#!/usr/bin/env bash
/opt/opendj/bin/ldapsearch --baseDN "dc=data" -p 1636  --bindPasswordFile $DIR_MANAGER_PW_FILE --useSSL \
   -h `hostname` \
   --bindDN "cn=Directory Manager"  \
   --trustStorePath  $KEYSTORE_FILE  --trustStorePasswordFile $KEYSTORE_PIN_FILE \
   "(objectclass=*)"
