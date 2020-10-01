
#######################################
# genRandomPass
# =============
#   create a string of random lowercase characters using openssl -rand.
#   The characters =/l+ are replaced with 1 or 0 for readability.  
# Arguments:
#   1: length of the random string.
# Returns:
#   random string.
#######################################
genRandomPass () {
    openssl rand -base64 ${1} | tr '[:upper:]' '[:lower:]' | tr =/ 0 | tr l+ 1
}

#######################################
# useRandomPass
# =============
# create a secret containing a random string with a give length if the secret does not exist. 
# If the secret already exists, do nothing or optionally print it. 
 
# Globals:
#   GEN_PATH: the path to where the secret is created.
# Arguments:
#   1: the name of the secret in GEN_PATH
#   2: the length of the secret
#   3: if this arg is "print", print the secret after reading it and/or generating it.
# Returns:
#   random string if arg 3 is "print".
#######################################

# $1 Secret path
# $2 Password length
# $3 if "print", print the generated pw to console
# $4 soft override. Use this value instead of the value found in OVERRIDE_ALL_PASSWORDS.txt . Ignored if OVERRIDE_ALL_PASSWORDS.txt is not found
# $5 hard override. Use this value for the password regardless of any other condition.
useRandomPass () {
    LEN=${2:-"24"}

    decryptIfExists ${GEN_PATH}/${1}

    if [ ! -f ${GEN_PATH}/${1} ]; then
        mkdir -p $(dirname ${GEN_PATH}/${1})
        if [ -f config/OVERRIDE_ALL_PASSWORDS.txt ] || ([ $# -ge 5 ] && [ -n "$5" ]); then
            local overridePass=""
            if [ $# -ge 5 ] && [ -n "$5" ]; then
                overridePass=${5}            
            elif [ ${4-"!"} == "!" ]; then
                overridePass=$(< config/OVERRIDE_ALL_PASSWORDS.txt)
            else
                overridePass=${4}
            fi
            >&2 echo "WARNING: random password generation for ${GEN_PATH}/${1} has been overridden with the following password: ${overridePass}"
            >&2 echo "If you want passwords to be randomly generated, delete the OVERRIDE_ALL_PASSWORDS.txt file from the forgeops-secrets docker image."
            echo -n "${overridePass}" > ${GEN_PATH}/${1}
        else
            >&2 echo "Generating password ${GEN_PATH}/${1}"
            echo -n "$(genRandomPass ${LEN})" > ${GEN_PATH}/${1}
        fi
    fi

    if [ ${3:-"!"} == "print" ]; then
        cat ${GEN_PATH}/${1}
    fi

    if [ ! -f ${GEN_PATH}/${1}.gpg ]; then
        encryptFile ${GEN_PATH}/${1}
    fi
}

#######################################
# useSecret
# =============
# Print a secret value encrypted with the crypt.sh script. 
 
# Globals:
#   GEN_PATH: the path to where the secret is created.
# Arguments:
#   1: the contents of the secret value.
# Returns:
#  the secret string.
#######################################
useSecret () {
    decryptIfExists ${GEN_PATH}/${1}
    cat ${GEN_PATH}/${1}
}

#######################################
# decryptFile
# =============
# Decrypt a file using the crypt script.
#
# Arguments:
#   *: the path to the file to decrypt.
#
# Returns:
#   nothing.
#######################################
decryptFile () {
    FILE=$*
    # gpg --decrypt -q --batch --yes --output ${FILE/.gpg/} $FILE;
    # SCRIPT_QUIET="true" bin/crypt.sh -d $FILE
}

#######################################
# decryptIfExists
# =============
# Decrypt the file if it exists, otherwise do nothing.
#
# Arguments:
#   1:the file.
#
# Returns:
#   nothing.
#######################################
decryptIfExists () {
    if [ -f ${1}.gpg ]; then
        decryptFile ${1}.gpg
    fi
}

#######################################
# encryptFile
# =============
# encrypt a file using the crypt script.
#
# Arguments:
#   *: the path to the file to decrypt.
#
# Returns:
#   nothing.
#######################################
encryptFile () {
    FILE=$*
    # gpg --encrypt -q --batch --yes --output ${FILE}.gpg --recipient openbanking@forgerock.com $FILE;
    # OVERWRITE_GPG="true" SCRIPT_QUIET="true" GIT_IGNORE_PATH="./.gitignore" bin/crypt.sh -e $FILE
}

dskey_useDeploymentKey () {

    mkdir -p $(dirname ${GEN_PATH}/${1})

    if [ ! -f ${GEN_PATH}/${1} ]; then
        echo "[DS] creating deployment key ${1}"
        opendj/bin/dskeymgr create-deployment-key -f ${GEN_PATH}/${1} -w ${2}
    else
        echo "[DS] Skipping creating deployment key, ${1} already exists."
    fi
    DSKEY_KEY_PROPS="-k $(< ${GEN_PATH}/${1}) -w ${2}"
}

dskey_openKeyStore () {
    mkdir -p $(dirname ${GEN_PATH}/${1})
    DSKEY_STORE_PROPS="-K ${GEN_PATH}/${1} -W ${2}"
    DSKEY_STORE=${GEN_PATH}/${1}
    DSKEY_STOREPASS=${2}
}

dskey_wrapper () {

    local action=${1}
    shift
    
    if [ "${action}" == "export-ca-cert" ] ; then
         opendj/bin/dskeymgr ${action} ${DSKEY_KEY_PROPS} $*
    else
        if ! keytool -list -storetype pkcs12 -keystore ${DSKEY_STORE} -storepass ${DSKEY_STOREPASS} -alias ${2-"NONE"} >/dev/null; then
            opendj/bin/dskeymgr ${action} ${DSKEY_KEY_PROPS} ${DSKEY_STORE_PROPS} $*
        else
            echo "Skipping ${action} on ${2-"NONE"}, alias exists."
        fi
    fi

}

dskey_closeKeyStore () {
    DSKEY_STORE_PROPS=""
    DSKEY_STORE=""
    DSKEY_STOREPASS=""
}

dskey_closeDeploymentKey () {
    DSKEY_KEY_PROPS=""
}

#######################################
# openKeystore
# =============
# Set up a keystore file for use with subsequant keytoolgen, genRSA, genEC, genKey functions. This function must be run before those functions.
#
# Arguments:
#   1: path to keystore file.
#   2: The type of the keystore file.
#   3: the password to the keystore.
#   4: the password to private keys within the keystore.
#
# Returns:
#   nothing.
#######################################
openKeystore () {
    KEYSTORE=${GEN_PATH}/${1}
    STORE_TYPE=${2}
    STORE_PASS=${3}
    KEY_PASS=${4}


    mkdir -p $(dirname ${GEN_PATH}/${1})
    decryptIfExists ${GEN_PATH}/${1}

    if [ -f ${GEN_PATH}/${1} ] && ! keytool -list -keystore ${GEN_PATH}/${1} -storetype ${2} -storepass ${3} -keypass ${4} 2> >(grep -v "${KEYTOOL_STDERR_FILTER}") >/dev/null; then
        echo "-keystore ${GEN_PATH}/${1} -storetype ${2} -storepass ${3} -keypass ${4}"
        echo "-keystore ${KEYSTORE} -storetype ${STORE_TYPE} -storepass ${STORE_PASS} -keypass ${KEY_PASS}"
        echo "Can not access existing keystore ${GEN_PATH}/${1}, wrong password?"
        exit 10
    else
        KS_PROPS="-keystore ${KEYSTORE} -storetype ${STORE_TYPE} -storepass ${STORE_PASS} -keypass ${KEY_PASS}"
        KS_PROPS_IMPORT="-destkeystore ${KEYSTORE} -deststoretype ${STORE_TYPE} -deststorepass ${STORE_PASS} -destkeypass ${KEY_PASS}"
        echo "Using keystore: ${KEYSTORE}"
    fi
}

openCA () {
    CA_KEYSTORE=${GEN_PATH}/${1}
    CA_STORE_TYPE=${2}
    CA_STORE_PASS=${3}
    CA_KEY_PASS=${4}
    CA_ALIAS=${5}
    CA_DNAME=${6}
    CA_CERT=${GEN_PATH}/${7}

    decryptIfExists ${CA_KEYSTORE}

    if [ -f ${GEN_PATH}/${1} ] && ! keytool -list -keystore ${GEN_PATH}/${1} -storetype ${2} -storepass ${3} -keypass ${4} 2> >(grep -v "${KEYTOOL_STDERR_FILTER}") >/dev/null; then
        echo "Can not access existing CA keystore ${GEN_PATH}/${1}, wrong password?"
        exit 10
    else
        CA_PROPS="-keystore ${CA_KEYSTORE} -storetype ${CA_STORE_TYPE} -storepass ${CA_STORE_PASS} -keypass ${CA_KEY_PASS}"
        CA_PROPS_IMPORT="-destkeystore ${CA_KEYSTORE} -deststoretype ${CA_STORE_TYPE} -deststorepass ${CA_STORE_PASS} -destkeypass ${CA_KEY_PASS}"
    fi

    if [ ! -f ${GEN_PATH}/${1} ]; then
        initCA ${CA_DNAME}
    fi
}

initCA () {
    echo "[CA Keystore ${CA_KEYSTORE}] Creating CA ${CA_ALIAS}"
    keytool -genkeypair \
    ${CA_PROPS} \
    -alias $CA_ALIAS \
    -dname $1 \
    -keyalg RSA \
    -keysize 4096 \
    -ext KeyUsage="keyCertSign" \
    -ext BasicConstraints:"critical=ca:true" \
    -validity 7300 2> >(grep -v "${KEYTOOL_STDERR_FILTER}") >/dev/null

    echo "[CA Keystore ${CA_KEYSTORE}] Exporting CA ${CA_ALIAS} to file $CA_CERT"
    # Export the exampleCA public certificate so that it can be used in trust stores..
    keytool -export -v \
     ${CA_PROPS} \
    -alias $CA_ALIAS \
    -file $CA_CERT \
    -rfc 2> >(grep -v "${KEYTOOL_STDERR_FILTER}") >/dev/null

}

#######################################
# closeKeystore
# =============
# Encrypts the keystore with the encryptFile function. Keystore to do this denoted by the openKeystore function.
#
# Arguments:
#  none.
#
# Returns:
#   nothing.
#######################################
closeKeystore () {
    if [ ${KS_CHANGED} == "1" ]; then
        echo "Closing keystore ${KEYSTORE}, saving changes and re-encrypting."
        encryptFile ${KEYSTORE}
    else
        echo "Closing keystore ${KEYSTORE} without changes."

    fi
}

#######################################
# keytoolgen
# =============
# A wrapper for the keytool command, using keystore properties from openKeystore.
# Imports a static secret to a keystore, imports an entry from another keystore or runs a generic keystore command.
#
# Arguments:
#   *: the arguments passed through to the keytool command.
#
# Returns:
#   nothing.
#######################################
keytoolgen () {
    if keytool -list -alias ${3} ${KS_PROPS} 2> >(grep -v "${KEYTOOL_STDERR_FILTER}") >/dev/null; then
        echo "alias ${3} exists."
    else
        case "${1-"!"}" in
            '--force')

            ;;
            '-importpass')
                ALIAS=${3}
                IMP_PASS=${4}
                echo "[Keystore ${KEYSTORE}] Importing password with alias ${3}"
                echo ${IMP_PASS} | keytool -importpass -alias ${ALIAS} ${KS_PROPS} 2> /dev/null
                KS_CHANGED=1
            ;;
            '-importkeystore')
                keytool $* ${KS_PROPS_IMPORT} 2> /dev/null
                KS_CHANGED=1
            ;;
            '-import')
                keytool $* ${KS_PROPS_IMPORT} 2> /dev/null
                KS_CHANGED=1
            ;;
            *)
                keytool $* ${KS_PROPS} 2> /dev/null
                KS_CHANGED=1
            ;;
        esac
    fi

}

genRSA () {
    echo "[Keystore ${KEYSTORE}] Generating RSA keypair:${1} key size:${2}"
    keytoolgen -genkeypair -alias ${1} -dname "CN=${1},$DN" -keyalg RSA -keysize ${2} -sigalg SHA256WITHRSA --validity ${VALIDITY}

}

signRSA () {
    SSL_CERT_ALIAS=$1
    DNAME=$2
    SANS=$3

            # -dname "CN=ds" \
            # -ext SAN=DNS:ds-0,DNS:ds-1 \    

    decryptFile ${SMS_PATH}.gpg
    echo "[Keystore ${KEYSTORE}] Importing CA ${CA_ALIAS}"

    keytoolgen -import \
            -alias ${CA_ALIAS} \
            ${CA_PROPS_IMPORT} \
            -trustcacerts \
            -noprompt \
            -file ${CA_CERT}

    echo "[Keystore ${KEYSTORE}] Sigining $SSL_CERT_ALIAS with CA ${CA_ALIAS}"

    keytool -certreq \
            ${KS_PROPS} \
            -alias $SSL_CERT_ALIAS | \
            \
    keytool -gencert \
            ${CA_PROPS} \
            -dname CN=$DNAME \
            -ext SAN=$SANS \
            -alias $CA_ALIAS | \
            \
    keytool -importcert \
            ${KS_PROPS} \
            -alias $SSL_CERT_ALIAS

}

genEC () {
    echo "[Keystore ${KEYSTORE}] Generating EC keypair:${1} key size:${2}"
    keytoolgen -genkeypair -alias ${1} -dname "CN=${1},$DN"  -keyalg EC  -keysize ${2}  -sigalg SHA256withECDSA --validity ${VALIDITY}
}

genKey () {
    echo "[Keystore ${KEYSTORE}] Generating secret key:${1} algorythm:${2} key size:${3}"
    keytoolgen -genseckey -alias ${1} -keyalg ${2} -keysize ${3} 
}

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

genSshKey () {

    FNAME=$(basename ${GEN_PATH}/${1})
    DNAME=$(realpath $(dirname ${GEN_PATH}/${1}))

    if [ -f ${GEN_PATH}/${1}.gpg ] && [ -f ${GEN_PATH}/${1}.pub.gpg ]; then
        echo "GPG files exist for ${GEN_PATH}/${1}, using encrypted values."
        decryptFile ${GEN_PATH}/${1}.gpg
        decryptFile ${GEN_PATH}/${1}.pub.gpg
    fi

    mkdir -p ${DNAME}

    if [ ! -f ${GEN_PATH}/${1} ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local docker_cmd="apt update && apt -y install openssh-client && ssh-keygen -t rsa -b 4096 -C \"obri-amster@example.com\" -f /v/${FNAME} -q -N \"\""
            docker run --rm -v ${DNAME}:/v ubuntu bash -c "${docker_cmd}"
        else
            ssh-keygen -t rsa -b 4096 -C "obri-amster@example.com" -f ${GEN_PATH}/${1} -q -N ""
        fi
    fi

    # verify this is PEM format and convert from new OpenSSH format if not
    # https://github.com/ForgeCloud/ob-reference-implementation/issues/1671
    sshKeyFormat ${GEN_PATH}/${1}

    # verify the public and private keys match in case they were not just generated
    sshPrivatePubMatch ${GEN_PATH}/${1} ${GEN_PATH}/${1}.pub

    if [ ! -f ${GEN_PATH}/${1}.gpg ]; then
        encryptFile ${GEN_PATH}/${1}
        encryptFile ${GEN_PATH}/${1}.pub
    fi

}

sshKeyFormat () {
    # Check for keys in new OpenSSH format
    if [ "$(head -n1 ${1})" == "-----BEGIN OPENSSH PRIVATE KEY-----" ]; then
        chmod 0600 ${1}
	# Convert key to PEM format. Must temporarily chmod 600 or ssh-keygen will complain
        ssh-keygen -p -N "" -m PEM -f ${1}
        chmod 0644 ${1}
    fi
}

amsterKeyCheck () {
    if [ "$(head -n1 ${GEN_PATH}/${1})" != "-----BEGIN RSA PRIVATE KEY-----" ]; then
        echo "ERROR: ${GEN_PATH}/${1} key is not in the correct format for amster. Make sure to generate the key on linux."
        exit 50
    fi
}

sshPrivatePubMatch () {
    if ! diff -q <( ssh-keygen -y -e -f "${1}" ) <( ssh-keygen -y -e -f "${2}" ); then 
        echo "ERROR: ${1} private and public keys do not match."
        exit 60
    fi
}

concat () {

    local secretFile=$1
    local filesWithPaths=""

    decryptIfExists ${GEN_PATH}/${secretFile}
    shift

    for F in $*; do
        if [ -f ${GEN_PATH}/${F} ]; then
            decryptIfExists ${GEN_PATH}/${F}
            filesWithPaths="${filesWithPaths} ${GEN_PATH}/${F}"
        else
            decryptIfExists ${F}
            filesWithPaths="${filesWithPaths} ${F}"
        fi
    done

    mkdir -p $(dirname ${TEMP_PATH}/$secretFile)
    cat $filesWithPaths > ${TEMP_PATH}/$secretFile

    if [ -f ${GEN_PATH}/${secretFile} ] && diff -q ${GEN_PATH}/${secretFile} ${TEMP_PATH}/$secretFile; then 
        echo "[${secretFile}] already up to date, skipping."
    else
        echo "[${secretFile}] Concatenating files $*."
        mkdir -p $(dirname ${GEN_PATH}/$secretFile)
        cat $filesWithPaths > ${GEN_PATH}/${secretFile}
        encryptFile ${GEN_PATH}/${secretFile}
    fi

}

cpAttr () {
    mkdir -p $(dirname ${GEN_PATH}/${1})
    mkdir -p $(dirname ${GEN_PATH}/${2})
    cp ${GEN_PATH}/${1} ${GEN_PATH}/${2}
}

usage () {
    echo "bin/gen.sh <path> [--wipe]"
    echo "--wipe will overwrite ALL secrets in the path."
    echo "<path> is path to the environment directory, where the generic, tls and docker directories will be created"
    echo "       if they don't exist already."
    echo ""
    echo "NOTE: This tool expects to be run from the parent dir (ob-k8s-secrets), like this bin/gen.sh"
    exit 10
}

if [ "${1-"!"}" == "!" ]; then
    usage
fi

GEN_PATH=${1}/generic
DIR_PATH=${1}

if [ "${2-"!"}" == "--wipe" ]; then
    rm -Rf ${DIR_PATH}/*
fi
