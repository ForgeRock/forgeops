#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

echo "Setting up default OpenDJ instance."
touch /opt/opendj/BOOTSTRAPPING

INIT_OPTION="--addBaseEntry"

if [ -n "${NUMBER_SAMPLE_USERS+set}" ]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi

# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
/opt/opendj/setup -p 1389 --ldapsPort 1636 --enableStartTLS  \
  --adminConnectorPort 4444 \
  --instancePath /opt/opendj/data \
  --baseDN $BASE_DN -h localhost --rootUserPassword "$PASSWORD" \
  --acceptLicense \
  ${INIT_OPTION}

# If any optional LDIF files are present, load them.

if [ -d /opt/opendj/bootstrap/ldif ]; then
   echo "Found optional schema files in bootstrap/ldif. Will load them"
  for file in /opt/opendj/bootstrap/ldif/dj-userstore/*;  do
      echo "Loading $file"
       sed -e "s/@BASE_DN@/$BASE_DN/" -e "s/@userStoreRootSuffix@/$BASE_DN/"  -e "s/@DB_NAME@/userRoot/" <${file}  >/tmp/file.ldif
      /opt/opendj/bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -w ${PASSWORD} -f /tmp/file.ldif
      echo "  "
  done
fi

/opt/opendj/schedule_backup.sh
