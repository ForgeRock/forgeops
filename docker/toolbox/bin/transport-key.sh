#!/usr/bin/env sh

# Copyright (c) 2016-2017 ForgeRock AS. All Rights Reserved
#
#  Use of this code requires a commercial software license with ForgeRock AS.
#  or with one of its affiliates. All use shall be exclusively subject
#  to such license between the licensee and ForgeRock AS.

if [ $1 == "help" ]
then
    echo
    echo "generate"
    echo
    echo "$0 generate [keystore directory]"
    echo
    echo "Generates a suitable transport key in the specified keystore"
    echo
    echo
    echo "move"
    echo
    echo "$0 move [source keystore directory] [destination keystore directory]"
    echo
    echo "Moves the transport key from the source keystore to the destination keystore"
    echo "If the destination keystore does not exist, it will be created."
    echo "If the destination .storepass does not exist, the source .storepass will be used."
    echo "If the source .storepass does not exist, it will fail."
    echo "The .storepass contains the password to the keystore."
    echo
    echo
    echo "delete"
    echo
    echo "$0 delete [keystore directory]"
    echo
    echo "Deletes the transport key from a keystore."
    echo
fi

# Generates a suitable transport key in the OpenAM keystore. By default the key will use the .storepass as its .keypass.

if [ $1 == "generate" ]
then
    if [ -z "$2" ]
      then
        echo "No argument for OpenAM config directory supplied"
        exit 0
    fi

    OPENAM_DIR=$2

    echo "OpenAM dir : ${OPENAM_DIR}"

    cd "${OPENAM_DIR}"

    SRC_STORE_PASS=$( cat ".storepass" )
    echo "Source store pass : ${SRC_STORE_PASS}"

    # generate and store the secret transport key
    keytool -genseckey -alias sms.transport.key -keyalg AES -keysize 128 -storetype jceks -keystore keystore.jceks -storepass ${SRC_STORE_PASS} -keypass ${SRC_STORE_PASS}

    echo "Successfully generated"
    echo "Changes require a restart of OpenAM"

fi

# Moves the transport key from one keystore to another. If the destination doesn't have a keystore, one will be created.
# If the destination doesn't have a .storepass the source .storepass will be used

if [ $1 == "move" ]
then

    if [ -z "$2" ]
      then
        echo "No argument for source directory supplied"
        exit 0
    fi

    SRC_KEYSTORE_DIR=$2

    echo "Source directory : ${SRC_KEYSTORE_DIR}"

    if [ -z "$3" ]
      then
        echo "No argument for destination directory supplied"
        exit 0
    fi

    DEST_KEYSTORE_DIR=$3

    echo "Source directory : ${DEST_KEYSTORE_DIR}"

    cd "${SRC_KEYSTORE_DIR}"

    SRC_STORE_PASS=$( cat ".storepass" )
    echo "Source store pass : ${SRC_STORE_PASS}"

    if [ -f "${DEST_KEYSTORE_DIR}/.storepass" ]
    then
        DEST_STORE_PASS=$( cat "${DEST_KEYSTORE_DIR}/.storepass" )
        else
        DEST_STORE_PASS=${SRC_STORE_PASS}
        cp "${SRC_KEYSTORE_DIR}/.storepass" ${DEST_KEYSTORE_DIR}
    fi
    echo "Destination store pass : ${DEST_STORE_PASS}"

    # Import the exported keystore into the current openam keystore.
    keytool -importkeystore -srckeystore "${SRC_KEYSTORE_DIR}/keystore.jceks" -destkeystore "${DEST_KEYSTORE_DIR}/keystore.jceks" -srcstoretype jceks \
        -deststoretype jceks -srcalias "sms.transport.key" -destalias "sms.transport.key" -srckeypass "${SRC_STORE_PASS}" -destkeypass "${DEST_STORE_PASS}" \
        -srcstorepass "${SRC_STORE_PASS}" -deststorepass "${DEST_STORE_PASS}"

    echo "Successfully exported transport key"

fi

if [ $1 == "delete" ]
then
    if [ -z "$2" ]
      then
        echo "No argument for OpenAM config directory supplied"
        exit 0
    fi

    OPENAM_DIR=$2

    echo "OpenAM directory : ${OPENAM_DIR}"

    cd "${OPENAM_DIR}"

    SRC_STORE_PASS=$( cat ".storepass" )
    echo "Source store pass : ${SRC_STORE_PASS}"

    # Generate and store the secret transport key.
    keytool -delete -alias "sms.transport.key" -storetype jceks -keystore "${OPENAM_DIR}/keystore.jceks" -storepass "${SRC_STORE_PASS}"

    echo "Successfully deleted"
    echo "Changes require a restart of OpenAM"

fi

