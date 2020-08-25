#!/bin/bash

#
# Copyright 2019-2020 ForgeRock AS. All Rights Reserved
#


am-crypto() {
    java -jar /home/forgerock/crypto-tool.jar $@
}

# Additiomal place holder


export AM_STORES_SSL_ENABLED=false
export TRUSTSTORE_PATH=/var/run/secrets/truststore/cacerts
export TRUSTSTORE_PASSWORD=changeit

# Let AM docker base generat this
# export AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY=$(echo -n "$AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY" | base64)

export AM_STORES_USER_TYPE=LDAPv3ForForgeRockIAM

exec /home/forgerock/docker-entrypoint.sh
